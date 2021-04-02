using UnityEngine;
using UnityEngine.Timeline;

namespace Revision2021
{
    public class ShipControl : MonoBehaviour, ITimeControl
    {
        [SerializeField] Transform shipTransform;

        [SerializeField] Transform shipMeshTransform;

        [SerializeField] float DamegeAnimationSpeed = 2f;
        [SerializeField] float DamageAnimationIntensity = 4f;
        [SerializeField] float DamageAnimationFrequently = 10f;
        [SerializeField] float DamageRotation = 10f;

        readonly int shipPositionID = Shader.PropertyToID("_ShipPosition");
        readonly int shipDamageBeatID = Shader.PropertyToID("_ShipDamageBeat");

        float lastDamageBeat = -999;

        Vector3 PerlinNoise(float t)
        {
            float s = 0.1f;

            return new Vector3(
                2f * (Mathf.PerlinNoise(t, s) - 0.5f),
                2f * (Mathf.PerlinNoise(t, s * 2) - 0.5f),
                2f * (Mathf.PerlinNoise(t, s * 3) - 0.5f)
            );
        }

        float Fbm(float t)
        {
            float o = 8700304f;
            float sum = Mathf.Sin(t) + 0.5f * Mathf.Sin((t + o) * 2) + 0.25f * Mathf.Sin((t + o) * 4);
            return sum / (1 + 0.5f + 0.25f);
        }

        Vector3 FbmVector3(float t)
        {
            float o = 8700304f;
            return new Vector3(Fbm(t), Fbm(t + o), Fbm(t + o * 2));
        }

        public void SetTime(double time)
        {
            Shader.SetGlobalVector(shipPositionID, shipTransform.position);

            float shipDamageBeat = TimelineTimeControl.Beat - lastDamageBeat;
            Shader.SetGlobalFloat(shipDamageBeatID, shipDamageBeat);

            if (shipDamageBeat > 0)
            {
                var fbm = DamageAnimationIntensity * Mathf.Exp(-shipDamageBeat * DamegeAnimationSpeed) * FbmVector3((float)time * DamageAnimationFrequently);
                shipMeshTransform.localPosition = Vector3.Scale(new Vector3(1, 2, 1), fbm);
                shipMeshTransform.localEulerAngles = new Vector3(90, 0, 0) + DamageRotation * fbm;
            }
            else
            {
                shipMeshTransform.localPosition = Vector3.zero;
                shipMeshTransform.localEulerAngles = new Vector3(90, 0, 0);
            }
        }

        public void OnControlTimeStart()
        {
        }

        public void OnControlTimeStop()
        {
        }

        public void OnDamage(string name)
        {
            if (name == "ShipMesh")
            {
                lastDamageBeat = TimelineTimeControl.Beat;
            }
            else
            {

            }
        }
    }
}