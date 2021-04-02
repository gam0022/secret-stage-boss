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

        public void SetTime(double time)
        {
            Shader.SetGlobalVector(shipPositionID, shipTransform.position);

            float shipDamageBeat = TimelineTimeControl.Beat - lastDamageBeat;
            Shader.SetGlobalFloat(shipDamageBeatID, shipDamageBeat);

            if (shipDamageBeat > 0)
            {
                shipMeshTransform.localPosition = DamageAnimationIntensity * Mathf.Exp(-shipDamageBeat * DamegeAnimationSpeed) * PerlinNoise((float)time * DamageAnimationFrequently);
            }
        }

        public void OnControlTimeStart()
        {
        }

        public void OnControlTimeStop()
        {
        }

        public void OnDamage()
        {
            lastDamageBeat = TimelineTimeControl.Beat;
        }
    }
}