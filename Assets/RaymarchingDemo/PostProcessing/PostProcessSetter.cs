using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[ExecuteAlways]
public class PostProcessSetter : MonoBehaviour
{
    [SerializeField] float grayscaleBlend;
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
        glitch.flashColor.Override(flashColor);
        glitch.flashIntensity.Override(flashIntensity);
        glitch.blendColor.Override(blendColor);
        volume = PostProcessManager.instance.QuickVolume(postProcessGameObject.layer, 100f, glitch);

        isInitialized = true;
    }

    void Update()
    {
        Initialize();

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