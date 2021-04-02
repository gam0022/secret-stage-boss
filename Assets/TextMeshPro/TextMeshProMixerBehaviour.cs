using System;
using TMPro;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

public class TextMeshProMixerBehaviour : PlayableBehaviour
{
    string m_DefaultText;
    Color m_DefaultColor;
    float m_DefaultFontSize;

    string m_AssignedText;
    Color m_AssignedColor;
    float m_AssignedFontSize;

    TMP_Text m_TrackBinding;

    public override void ProcessFrame(Playable playable, FrameData info, object playerData)
    {
        m_TrackBinding = playerData as TMP_Text;

        if (m_TrackBinding == null)
            return;

        if (m_TrackBinding.text != m_AssignedText)
            m_DefaultText = m_TrackBinding.text;
        if (m_TrackBinding.color != m_AssignedColor)
            m_DefaultColor = m_TrackBinding.color;
        if (!Mathf.Approximately(m_TrackBinding.fontSize, m_AssignedFontSize))
            m_DefaultFontSize = m_TrackBinding.fontSize;

        int inputCount = playable.GetInputCount();

        Color blendedColor = Color.clear;
        float blendedFontSize = 0f;
        float totalWeight = 0f;
        float greatestWeight = 0f;
        int currentInputs = 0;

        for (int i = 0; i < inputCount; i++)
        {
            float inputWeight = playable.GetInputWeight(i);
            ScriptPlayable<TextMeshProBehaviour> inputPlayable = (ScriptPlayable<TextMeshProBehaviour>)playable.GetInput(i);
            TextMeshProBehaviour input = inputPlayable.GetBehaviour();

            blendedColor += input.color * inputWeight;
            blendedFontSize += input.fontSize * inputWeight;
            totalWeight += inputWeight;

            if (inputWeight > greatestWeight)
            {
                m_AssignedText = input.text;
                m_TrackBinding.text = m_AssignedText;
                greatestWeight = inputWeight;
            }

            if (!Mathf.Approximately(inputWeight, 0f))
                currentInputs++;
        }

        m_AssignedColor = blendedColor + m_DefaultColor * (1f - totalWeight);
        m_TrackBinding.color = m_AssignedColor;
        m_AssignedFontSize = blendedFontSize + m_DefaultFontSize * (1f - totalWeight);
        m_TrackBinding.fontSize = m_AssignedFontSize;

        if (currentInputs != 1 && 1f - totalWeight > greatestWeight)
        {
            m_TrackBinding.text = m_DefaultText;
        }
    }
}
