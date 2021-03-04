using UnityEngine;
using UnityEngine.Timeline;

public class TimelineTimeControl : MonoBehaviour, ITimeControl
{
    [SerializeField] int bpm = 120;
    [SerializeField] AudioSpectrum audioSpectrum;

    readonly int timelineTimeID = Shader.PropertyToID("_TimelineTime");
    readonly int beatID = Shader.PropertyToID("_Beat");

    readonly int audioSpectrumLevelLengthID = Shader.PropertyToID("_AudioSpectrumLevelLength");
    readonly int audioSpectrumLevelsID = Shader.PropertyToID("_AudioSpectrumLevels");
    readonly int audioSpectrumPeakLevelsID = Shader.PropertyToID("_AudioSpectrumPeakLevels");
    readonly int audioSpectrumMeanLevelsID = Shader.PropertyToID("_AudioSpectrumMeanLevels");


    bool isInitialized = false;

    public void SetTime(double time)
    {
        Shader.SetGlobalFloat(timelineTimeID, (float)time);
        Shader.SetGlobalFloat(beatID, (float)time * bpm / 60);
        Shader.SetGlobalFloat(audioSpectrumLevelLengthID, audioSpectrum.Levels.Length);

        if (isInitialized)
        {
            Shader.SetGlobalFloatArray(audioSpectrumLevelsID, audioSpectrum.Levels);
            Shader.SetGlobalFloatArray(audioSpectrumPeakLevelsID, audioSpectrum.PeakLevels);
            Shader.SetGlobalFloatArray(audioSpectrumMeanLevelsID, audioSpectrum.MeanLevels);
        }
        else
        {
            var levels = new float[32];
            Shader.SetGlobalFloatArray(audioSpectrumLevelsID, levels);
            Shader.SetGlobalFloatArray(audioSpectrumPeakLevelsID, levels);
            Shader.SetGlobalFloatArray(audioSpectrumMeanLevelsID, levels);
            isInitialized = true;
        }
    }

    public void OnControlTimeStart()
    {
    }

    public void OnControlTimeStop()
    {
#if !UNITY_EDITOR
        Application.Quit();
#endif
    }

}
