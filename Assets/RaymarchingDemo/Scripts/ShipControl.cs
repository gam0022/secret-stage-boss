using UnityEngine;
using UnityEngine.Timeline;

namespace Revision2021
{
    public class ShipControl : MonoBehaviour, ITimeControl
    {
        [SerializeField] Transform shipTransform;

        readonly int shipPositionID = Shader.PropertyToID("_ShipPosition");

        public void SetTime(double time)
        {
            Shader.SetGlobalVector(shipPositionID, shipTransform.position);
        }

        public void OnControlTimeStart()
        {
        }

        public void OnControlTimeStop()
        {
        }
    }
}