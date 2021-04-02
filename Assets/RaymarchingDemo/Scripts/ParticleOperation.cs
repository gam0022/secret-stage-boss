using UnityEngine;

namespace Revision2021
{
    public class ParticleOperation : MonoBehaviour
    {
        [SerializeField] ShipControl shipControl;
        ParticleSystem ps;
        ParticleSystem.Particle[] m_Particles;

        public Transform target;
        public float _rotSpeed = 180.0f;  // 1秒間に回転する角度


        void Start()
        {
            ps = GetComponent<ParticleSystem>();
        }

        // ターゲットをセットする
        void Update()
        {
            m_Particles = new ParticleSystem.Particle[ps.main.maxParticles];
            int numParticlesAlive = ps.GetParticles(m_Particles);

            for (int i = 0; i < numParticlesAlive; i++)
            {
                var velocity = m_Particles[i].velocity;
                var position = m_Particles[i].position;

                // ターゲットへのベクトル
                var direction = target.position - position;
                // var direction = ps.transform.InverseTransformPoint(target.TransformPoint(target.position)) - position;

                // ターゲットまでの角度
                float angleDiff = Vector3.Angle(velocity, direction);

                // 回転角
                float angleAdd = (_rotSpeed * Time.deltaTime);

                // ターゲットへ向けるクォータニオン
                Quaternion rotTarget = Quaternion.FromToRotation(velocity, direction);
                if (angleDiff <= angleAdd)
                {
                    // ターゲットが回転角以内なら完全にターゲットの方を向く
                    m_Particles[i].velocity = (rotTarget * velocity);
                }
                else
                {
                    // ターゲットが回転角の外なら、指定角度だけターゲットに向ける
                    float t = (angleAdd / angleDiff);
                    m_Particles[i].velocity = Quaternion.Slerp(Quaternion.identity, rotTarget, t) * velocity;
                }
            }

            ps.SetParticles(m_Particles, numParticlesAlive);
        }

        private void OnParticleCollision(GameObject other)
        {
            Debug.Log("OnParticleCollision : " + other);
            shipControl.OnDamage();
        }
    }
}