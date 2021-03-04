using System;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

[Serializable]
public class TextMeshProClip : PlayableAsset, ITimelineClipAsset
{
    public TextMeshProBehaviour template = new TextMeshProBehaviour ();

    public ClipCaps clipCaps
    {
        get { return ClipCaps.Blending; }
    }

    public override Playable CreatePlayable (PlayableGraph graph, GameObject owner)
    {
        var playable = ScriptPlayable<TextMeshProBehaviour>.Create (graph, template);
        return playable;
    }
}
