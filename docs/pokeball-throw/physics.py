"""Static reconstruction of Pokemon GO 0.435.2 ordinary throw math.

Uses extracted prefab defaults. Scene geometry, camera pose, AR mode, and live
configuration are inputs, not inferred constants. No game network connection.
"""
from dataclasses import dataclass
from math import cos, sin, tan, sqrt, log1p, radians, hypot
from typing import Sequence

@dataclass(frozen=True)
class Settings:
    gravity: float = -9.8100004196167
    flick_window: float = 0.13
    swipe_angle_range: float = 140.0
    spin_multiplier: float = 3.0
    spin_window: float = 0.07
    spin_threshold: float = 0.4
    max_angular_velocity: float = 50.0
    curve: tuple = (5.0, 0.25, 0.25)
    min_angle: float = 36.0
    max_angle: float = 45.0
    max_angle_height: float = 1.5
    max_speed: float = 15.0
    speed_threshold: float = 0.2
    velocity_multiplier: tuple = (1.0, 4.0)
    overshoot: float = 0.8
    undershoot: float = 0.15

DEFAULTS = Settings()

def clamp01(x):
    return max(0.0, min(1.0, x))

def swipe_velocity(samples: Sequence[tuple], width, height, now=None, settings=DEFAULTS):
    """Samples are (time_seconds, x_pixels, y_pixels), Unity bottom-left origin.

    Equal-weight mean of successive normalized segment velocities, walking
    backwards. Includes the first segment whose START precedes the window.
    Rejects nonincreasing timestamps rather than reproducing undefined input.
    """
    if width <= 0 or height <= 0 or len(samples) < 2:
        raise ValueError('Need positive dimensions and at least two samples')
    if any(b[0] <= a[0] for a,b in zip(samples,samples[1:])):
        raise ValueError('Sample times must increase')
    now = samples[-1][0] if now is None else now
    vx = vy = 0.0
    count = 0
    for i in range(len(samples)-1,0,-1):
        a,b = samples[i-1],samples[i]
        dt=b[0]-a[0]
        vx+=(b[1]-a[1])/width/dt
        vy+=(b[2]-a[2])/height/dt
        count+=1
        if a[0] < now-settings.flick_window: break
    return vx/count, vy/count

def valid_swipe(v, settings=DEFAULTS):
    speed=hypot(*v)
    return v[1]>0 and speed>1e-5 and v[1]/speed>cos(radians(settings.swipe_angle_range/2))

def spin_points(samples, mode='time', settings=DEFAULTS):
    """Return the three sample positions selected by the two observed handlers."""
    n=len(samples)
    if n<3:return None
    if mode=='frame':return tuple(p[1:] for p in samples[-3:])
    if mode!='time':raise ValueError('mode must be frame or time')
    end=n-1;window=settings.spin_window
    if samples[end][0]-samples[0][0]<window:return None
    middle=n-2;start=n-3
    while samples[end][0]-samples[start][0]<window:
        if samples[start][0]>samples[end][0]-window*.5:middle=start
        start-=1
        if start<0: return None
    if middle==end:middle-=1
    return samples[start][1:],samples[middle][1:],samples[end][1:]

def spin_impulse(points, width, height, settings=DEFAULTS):
    """Signed gesture scalar; game calls AddRelativeTorque((0,0,-scalar), Impulse).

    Conversion to angular velocity belongs to Rigidbody inertia/PhysX. We do
    not guess an inertia tensor or silently equate impulse with release spin.
    """
    if points is None:return 0.0
    a,b,c=[(p[0]/width,p[1]/height) for p in points]
    return settings.spin_multiplier*((b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]))

def target_speed(angle_radians, ball, target, gravity=DEFAULTS.gravity):
    """RVA 0xacd7b4c: full 3D separation, ABS before SQRT, then divide by cos.

    Deliberately preserves these choices, rather than substituting textbook
    horizontal range. Singular/nonfinite configurations are invalid inputs.
    """
    distance=sqrt(sum((a-b)**2 for a,b in zip(target,ball)))
    height=target[1]-ball[1]
    denominator=2*(distance*tan(angle_radians)-height)
    if abs(denominator)<1e-12 or abs(cos(angle_radians))<1e-12:
        raise ValueError('Singular ballistic target')
    return sqrt(abs(distance*distance*gravity/denominator))/cos(angle_radians)

def rotate_y(v, yaw_degrees):
    c,s=cos(radians(yaw_degrees)),sin(radians(yaw_degrees))
    return (c*v[0]+s*v[2],v[1],-s*v[0]+c*v[2])

def rotate_quaternion(v,q):
    x,y,z,w=q
    return ((1-2*y*y-2*z*z)*v[0]+(2*x*y-2*z*w)*v[1]+(2*x*z+2*y*w)*v[2],
            (2*x*y+2*z*w)*v[0]+(1-2*x*x-2*z*z)*v[1]+(2*y*z-2*x*w)*v[2],
            (2*x*z-2*y*w)*v[0]+(2*y*z+2*x*w)*v[1]+(1-2*x*x-2*y*y)*v[2])

def launch(v, ball, target, height_off_ground=0.0, camera_yaw=0.0,
           ar_rotation=None, settings=DEFAULTS):
    """Returns launch state, or None for a rejected swipe.

    Ordinary non-AR branch uses yaw only and speed assistance. Supplying an
    AR camera quaternion selects the observed unassisted full-rotation branch.
    Position is the actual ball release position, not its spawn position.
    """
    if not valid_swipe(v,settings):return None
    mx,my=settings.velocity_multiplier
    x=(-1 if v[0]<0 else 1)*mx*log1p(abs(v[0]))
    forward=my*log1p(v[1])
    delta=(settings.max_angle-settings.min_angle)%360
    if delta>180:delta-=360
    degrees=settings.min_angle+delta*clamp01(height_off_ground/settings.max_angle_height)
    theta=radians(degrees)
    raw=(x,forward*sin(theta),forward*cos(theta))
    magnitude=sqrt(sum(a*a for a in raw))
    speed=min(magnitude,settings.max_speed)
    if speed<=settings.speed_threshold:return None
    ideal=target_speed(theta,ball,target,settings.gravity)
    corrected=speed
    if ar_rotation is None:
        correction=settings.overshoot if speed>ideal else settings.undershoot
        corrected=speed+(ideal-speed)*clamp01(correction)
    velocity=tuple(a/magnitude*corrected for a in raw)
    velocity=rotate_y(velocity,camera_yaw) if ar_rotation is None else rotate_quaternion(velocity,ar_rotation)
    return dict(position=tuple(ball),velocity=velocity,angle_degrees=degrees,
                raw_speed=magnitude,capped_speed=speed,target_speed=ideal,speed=corrected)

def curve_acceleration(normalized_spin, camera_rotation=(0,0,0,1), settings=DEFAULTS):
    """Release spin = InverseTransformDirection(angularVelocity).z / maxAngularVelocity.

    Stored once at flight entry, applied using ForceMode.Acceleration on each
    fixed update. At/below the threshold, no curve force is stored.
    """
    if abs(normalized_spin)<=settings.spin_threshold:return (0.0,0.0,0.0)
    x,y,z=settings.curve;s=abs(normalized_spin)
    return rotate_quaternion((x*normalized_spin,y*s,z*s),camera_rotation)

def trajectory(state, normalized_spin=0.0, duration=2.0, dt=0.02,
               camera_rotation=(0,0,0,1), settings=DEFAULTS):
    """Free-flight semi-implicit Euler, no collisions, bounces or catching.

    Fixed-step timing/float rounding can differ from Unity PhysX. A 0.02s step
    is a caller-selected default, not an assertion about the game's runtime.
    """
    if dt<=0 or duration<0:raise ValueError('Invalid time interval')
    p=list(state['position']);v=list(state['velocity'])
    a=list(curve_acceleration(normalized_spin,camera_rotation,settings));a[1]+=settings.gravity
    yield (0.0,*p,*v)
    t=0.0
    while t<duration-1e-12:
        h=min(dt,duration-t)
        for k in range(3):v[k]+=a[k]*h;p[k]+=v[k]*h
        t+=h
        yield(t,*p,*v)

if __name__=='__main__':
    import argparse,csv,sys,json
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--swipe',nargs=2,type=float,default=[1.2,3.0],metavar=('VX','VY'))
    p.add_argument('--ball',nargs=3,type=float,default=[0,1,0])
    p.add_argument('--target',nargs=3,type=float,default=[0,1,4])
    p.add_argument('--height',type=float,default=0)
    p.add_argument('--spin',type=float,default=-.8)
    p.add_argument('--duration',type=float,default=1.5)
    p.add_argument('--dt',type=float,default=.02)
    args=p.parse_args();state=launch(args.swipe,args.ball,args.target,args.height)
    if state is None:p.error('Swipe rejected by angle/speed threshold')
    print(json.dumps(state),file=sys.stderr)
    w=csv.writer(sys.stdout);w.writerow(['t','x','y','z','vx','vy','vz'])
    w.writerows(trajectory(state,args.spin,args.duration,args.dt))
