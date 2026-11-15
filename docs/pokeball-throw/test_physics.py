import math,unittest
from dataclasses import replace
from physics import *

class PhysicsTests(unittest.TestCase):
    def test_segment_average_and_crossing_window(self):
        # Irregular sampling distinguishes arithmetic segment averaging from
        # displacement/elapsed-time and verifies the boundary-crossing segment.
        samples=[(0,0,0),(.1,0,100),(.3,0,500),(.35,0,650)]
        self.assertAlmostEqual(swipe_velocity(samples,1000,1000)[1],2.5)

    def test_resolution_invariance(self):
        s=[(0,0,0),(.05,50,100),(.1,100,200)]
        self.assertEqual(swipe_velocity(s,1000,2000),swipe_velocity([(t,2*x,2*y) for t,x,y in s],2000,4000))

    def test_gate(self):
        self.assertFalse(valid_swipe((0,-1)))
        self.assertFalse(valid_swipe((10,1)))
        self.assertTrue(valid_swipe((1,1)))
        self.assertIsNone(launch((0,.001),(0,1,0),(0,1,4)))

    def test_speed_assistance_and_cap_order(self):
        ball=(0,1,0);target=(0,1,4)
        for swipe in [(0,.3),(0,1000)]:
            state=launch(swipe,ball,target)
            k=.8 if state['capped_speed']>state['target_speed'] else .15
            self.assertAlmostEqual(state['speed'],state['capped_speed']*(1-k)+state['target_speed']*k)
        # Assistance follows the cap and can lift speed above that cap.
        s=launch((0,1000),ball,(0,1,100))
        self.assertEqual(s['capped_speed'],15)
        self.assertGreater(s['speed'],15)

    def test_spin_threshold_and_mirror(self):
        self.assertEqual(curve_acceleration(.4),(0,0,0))
        a,b=curve_acceleration(.8),curve_acceleration(-.8)
        self.assertEqual(a[0],-b[0]);self.assertEqual(a[1:],b[1:])
        tri=((0,0),(100,0),(100,100))
        self.assertAlmostEqual(spin_impulse(tri,1000,1000),-spin_impulse(tuple(reversed(tri)),1000,1000))

    def test_time_spin_selection(self):
        samples=[(i*.01,i,i) for i in range(11)]
        p=spin_points(samples)
        self.assertEqual(p[-1],(10,10))
        self.assertLessEqual(samples[p[0][0]][0],.03+1e-12)
        self.assertEqual(p[1],(7,7))
        self.assertIsNone(spin_points(samples[:3]))

    def test_flight_converges_to_constant_acceleration(self):
        s=launch((1,3),(0,1,0),(0,1,4));a=curve_acceleration(-.8);a=(a[0],a[1]+DEFAULTS.gravity,a[2]);T=.6;dt=.001
        row=list(trajectory(s,-.8,T,dt))[-1]
        for k in range(3):
            exact=s['position'][k]+s['velocity'][k]*T+.5*a[k]*T*T
            self.assertAlmostEqual(row[1+k]-exact,.5*a[k]*T*dt,places=8)

if __name__=='__main__':unittest.main()
