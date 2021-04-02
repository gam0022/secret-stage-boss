using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[ExecuteAlways]
public class PostProcessSetter : MonoBehaviour
{
    [SerializeField] float intensityBase;
    [SerializeField] float intensityBeat;
    [SerializeField] float intensityAudioSpectrum;

    [SerializeField] float glitchUvIntensity;
    [SerializeField] float distortionIntensity;
    [SerializeField] float rgbShiftIntensity;

    [SerializeField] float noiseIntensity;

    [SerializeField] Color flashColor = Color.white;
    [SerializeField] float flashIntensity = 0;
    [SerializeField] Color blendColor = Color.clear;

    [SerializeField] Color fogColor = Color.black;

    [SerializeField] GameObject postProcessGameObject;

    bool isInitialized = false;

    PostProcessVolume volume;
    Grayscale grayscale;
    Glitch glitch;

    void Initialize()
    {
        if (isInitialized)
        {
            return;
        }

        glitch = ScriptableObject.CreateInstance<Glitch>();
        glitch.enabled.Override(true);

        glitch.glitchUvIntensity.Override(glitchUvIntensity);
        glitch.distortionIntensity.Override(distortionIntensity);
        glitch.rgbShiftIntensity.Override(rgbShiftIntensity);
        glitch.noiseIntensity.Override(noiseIntensity);

        glitch.flashColor.Override(flashColor);
        glitch.flashIntensity.Override(flashIntensity);
        glitch.blendColor.Override(blendColor);

        volume = PostProcessManager.instance.QuickVolume(postProcessGameObject.layer, 100f, glitch);

        isInitialized = true;
    }

    void Update()
    {
        Initialize();

        glitch.glitchUvIntensity.value = glitchUvIntensity;
        glitch.distortionIntensity.value = distortionIntensity;
        glitch.rgbShiftIntensity.value = rgbShiftIntensity;
        glitch.noiseIntensity.value = noiseIntensity;

        glitch.flashColor.value = flashColor;
        glitch.flashIntensity.value = flashIntensity;
        glitch.blendColor.value = blendColor;

        RenderSettings.fogColor = fogColor;
    }

    void OnDestroy()
    {
        if (volume != null)
        {
            RuntimeUtilities.DestroyVolume(volume, true, true);
        }
    }
}