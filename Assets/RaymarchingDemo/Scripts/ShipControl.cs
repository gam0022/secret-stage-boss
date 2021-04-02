using UnityEngine;
using UnityEngine.Timeline;

namespace Revision2021
{
    public class ShipControl : MonoBehaviour, ITimeControl
    {
        [SerializeField] Transform shipTransform;

        readonly int shipPositionID = Shader.PropertyToID("_ShipPosition");
        readonly int shipDamageBeatID = Shader.PropertyToID("_ShipDamageBeat");

        float lastDamageBeat = -999;

        public void SetTime(double time)
        {
            Shader.SetGlobalVector(shipPositionID, shipTransform.position);
            Shader.SetGlobalFloat(shipDamageBeatID, TimelineTimeControl.Beat - lastDamageBeat);
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