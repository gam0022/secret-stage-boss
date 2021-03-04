using UnityEngine;
using UnityEngine.Timeline;

public class SimpleBeatControl : MonoBehaviour, ITimeControl
{
    [SerializeField] int bpm = 120;

    readonly int timelineTimeID = Shader.PropertyToID("_TimelineTime");
    readonly int beatID = Shader.PropertyToID("_Beat");

    // タイムラインクリップがアクティブな各フレームで呼び出されます。
    public void SetTime(double time)
    {
        Shader.SetGlobalFloat(timelineTimeID, (float)time);
        Shader.SetGlobalFloat(beatID, (float)time * bpm / 60);
    }

    // 関連するタイムラインクリップがアクティブになると、呼び出されます。
    public void OnControlTimeStart()
    {
    }

    // 関連するタイムラインクリップが非アクティブになると、呼び出されます。
    public void OnControlTimeStop()
    {
    }
}
