using UnityEngine;
using UnityEngine.Timeline;

namespace Revision2021
{
    public class BossControl : MonoBehaviour, ITimeControl
    {
        [SerializeField] Transform target;
        [SerializeField] Vector3 offset = new Vector3(0, 0, -20);


        public void SetTime(double time)
        {
            var p = target.position + offset;
            p.y += 0.1f * Mathf.Sin((float)(Mathf.PI * 2f * time));
            transform.position = p;
        }

        public void OnControlTimeStart()
        {
        }

        public void OnControlTimeStop()
        {
        }
    }
}