using System;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;
using TMPro;

[Serializable]
public class TextMeshProBehaviour : PlayableBehaviour
{
    public string text = "hello";
    public Color color = new Color(1f, 1f, 1f, 1f);
    public float fontSize = 36f;
}
