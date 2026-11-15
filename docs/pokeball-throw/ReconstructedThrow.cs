// Independent port of recovered ordinary throw equations, Pokemon GO 0.435.2.
// Unity 6 API. No Niantic classes/assets/networking required.
// Inputs: release position, normalized swipe velocity, encounter height,
// camera rotation and normalized release spin. See README.md for evidence.
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public sealed class ReconstructedThrow : MonoBehaviour
{
    public Vector3 curveModifier = new Vector3(5f, .25f, .25f);
    public Vector2 velocityMultiplier = new Vector2(1f, 4f);
    public float minAngle = 36f, maxAngle = 45f, maxAngleHeight = 1.5f;
    public float maxSpeed = 15f, speedThreshold = .2f;
    public float overshootCorrection = .8f, undershootCorrection = .15f;
    public float spinThreshold = .4f, maxAngularVelocity = 50f;
    public float spinMultiplier = 3f, angularDamping = 1f;
    public float swipeAngleRange = 140f;
    Rigidbody body;
    Vector3 flightAcceleration;
    bool flying;

    void Awake()
    {
        body = GetComponent<Rigidbody>();
        body.mass = 1f;
        body.linearDamping = 0f;
        body.angularDamping = angularDamping;
        body.maxAngularVelocity = maxAngularVelocity;
        body.useGravity = false;
    }

    // Supply a selected triple from the frame/time-based gesture handler.
    // Screen coordinates have Unity's bottom-left origin.
    public void ApplySpin(Vector2 a, Vector2 b, Vector2 c, Vector2 screenSize)
    {
        a /= screenSize; b /= screenSize; c /= screenSize;
        float impulse = spinMultiplier * ((b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x));
        body.AddRelativeTorque(Vector3.forward * -impulse, ForceMode.Impulse);
    }

    public float NormalizedSpin =>
        transform.InverseTransformDirection(body.angularVelocity).z / body.maxAngularVelocity;

    public static float TargetSpeed(float angleRadians, Vector3 ball, Vector3 target, float gravityY)
    {
        float distance = Vector3.Distance(ball, target); // Intentionally 3D.
        float height = target.y - ball.y;
        return Mathf.Sqrt(Mathf.Abs(distance * distance * gravityY /
               (2f * (distance * Mathf.Tan(angleRadians) - height)))) / Mathf.Cos(angleRadians);
    }

    // Camera rotation must correspond to the encounter camera at release.
    // heightOffGround is the Pokemon's reported height, not target.y-ball.y.
    public bool Release(Vector2 swipeVelocity, Vector3 target, float heightOffGround,
                        Quaternion cameraRotation, bool arMode = false)
    {
        if (swipeVelocity.y <= 0f || swipeVelocity.normalized.y <= Mathf.Cos(.5f*swipeAngleRange*Mathf.Deg2Rad))
            return false;
        float angle = Mathf.LerpAngle(minAngle, maxAngle, heightOffGround/maxAngleHeight)*Mathf.Deg2Rad;
        float lateral = Mathf.Sign(swipeVelocity.x)*velocityMultiplier.x*Mathf.Log(1f+Mathf.Abs(swipeVelocity.x));
        float forward = velocityMultiplier.y*Mathf.Log(1f+swipeVelocity.y);
        Vector3 raw = new Vector3(lateral, forward*Mathf.Sin(angle), forward*Mathf.Cos(angle));
        float speed = Mathf.Min(raw.magnitude, maxSpeed);
        if (speed <= speedThreshold) return false;
        float ideal = TargetSpeed(angle, transform.position, target, Physics.gravity.y);
        Quaternion launchRotation = cameraRotation;
        if (!arMode)
        {
            speed = Mathf.Lerp(speed, ideal, speed > ideal ? overshootCorrection : undershootCorrection);
            launchRotation = Quaternion.Euler(0f, cameraRotation.eulerAngles.y, 0f);
        }
        // Curve acceleration is sampled at flight entry and retained, even
        // though the visible ball's angular velocity continues to damp.
        float spin = NormalizedSpin;
        flightAcceleration = Mathf.Abs(spin) > spinThreshold
            ? cameraRotation * new Vector3(curveModifier.x*spin,
                curveModifier.y*Mathf.Abs(spin), curveModifier.z*Mathf.Abs(spin))
            : Vector3.zero;
        body.isKinematic = false;
        body.useGravity = true;
        body.linearVelocity = launchRotation * (raw.normalized * speed);
        flying = true;
        return true;
    }

    void FixedUpdate()
    {
        if (flying) body.AddForce(flightAcceleration, ForceMode.Acceleration);
    }

    // This demo stops its added curve force at first contact. The game's
    // hit, miss, reflection, catch and timeout state machine is outside scope.
    void OnCollisionEnter(Collision collision) { flying = false; }
    public void StopFlight() { flying = false; }
}
