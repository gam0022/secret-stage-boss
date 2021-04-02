using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(GlitchRenderer), PostProcessEvent.AfterStack, "Custom/Glitch")]
public sealed class Glitch : PostProcessEffectSettings
{
    [Range(0f, 1f), Tooltip("Intensity Base")] public FloatParameter intensityBase = new FloatParameter { value = 0f };
    [Range(0f, 1f), Tooltip("Intensity Beat")] public FloatParameter intensityBeat = new FloatParameter { value = 0f };
    [Range(0f, 20f), Tooltip("Intensity AudioSpectrum")] public FloatParameter intensityAudioSpectrum = new FloatParameter { value = 0f };

    [Range(0f, 1f), Tooltip("Glitch Uv Intensity")] public FloatParameter glitchUvIntensity = new FloatParameter { value = 0f };
    [Range(0f, 1f), Tooltip("Distortion Intensity")] public FloatParameter distortionIntensity = new FloatParameter { value = 0f };
    [Range(0f, 1f), Tooltip("RGB Shift Intensity")] public FloatParameter rgbShiftIntensity = new FloatParameter { value = 0f };
    [Range(0f, 1f), Tooltip("Noise Intensity")] public FloatParameter noiseIntensity = new FloatParameter { value = 0f };


    [Tooltip("Flash Color")] public ColorParameter flashColor = new ColorParameter { value = Color.white };
    [Range(0f, 20f), Tooltip("Flash Intensity")] public FloatParameter flashIntensity = new FloatParameter { value = 0f };
    [Tooltip("Blend Color")] public ColorParameter blendColor = new ColorParameter { value = Color.white };
}
public sealed class GlitchRenderer : PostProcessEffectRenderer<Glitch>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/Glitch"));

        sheet.properties.SetFloat("_IntensityBase", settings.intensityBase);
        sheet.properties.SetFloat("_IntensityBeat", settings.intensityBeat);
        sheet.properties.SetFloat("_IntensityAudioSpectrum", settings.intensityAudioSpectrum);

        sheet.properties.SetFloat("_GlitchUvIntensity", settings.glitchUvIntensity);
        sheet.properties.SetFloat("_DistortionIntensity", settings.distortionIntensity);
        sheet.properties.SetFloat("_RgbShiftIntensity", settings.rgbShiftIntensity);
        sheet.properties.SetFloat("_NoiseIntensity", settings.noiseIntensity);

        sheet.properties.SetColor("_FlashColor", settings.flashColor);
        sheet.properties.SetFloat("_FlashIntensity", settings.flashIntensity);
        sheet.properties.SetColor("_BlendColor", settings.blendColor);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}