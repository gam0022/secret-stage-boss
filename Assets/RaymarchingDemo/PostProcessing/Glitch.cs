﻿using System;
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
    readonly int glitchUvIntensityID = Shader.PropertyToID("_GlitchUvIntensity");
    readonly int distortionIntensityID = Shader.PropertyToID("_DistortionIntensity");
    readonly int rgbShiftIntensityID = Shader.PropertyToID("_RgbShiftIntensity");
    readonly int noiseIntensityID = Shader.PropertyToID("_NoiseIntensity");

    readonly int flashColorID = Shader.PropertyToID("_FlashColor");
    readonly int flashIntensityID = Shader.PropertyToID("_FlashIntensity");
    readonly int blendColorID = Shader.PropertyToID("_BlendColor");


    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/Glitch"));

        sheet.properties.SetFloat("_IntensityBase", settings.intensityBase);
        sheet.properties.SetFloat("_IntensityBeat", settings.intensityBeat);
        sheet.properties.SetFloat("_IntensityAudioSpectrum", settings.intensityAudioSpectrum);

        sheet.properties.SetFloat(glitchUvIntensityID, settings.glitchUvIntensity);
        sheet.properties.SetFloat(distortionIntensityID, settings.distortionIntensity);
        sheet.properties.SetFloat(rgbShiftIntensityID, settings.rgbShiftIntensity);
        sheet.properties.SetFloat(noiseIntensityID, settings.noiseIntensity);

        sheet.properties.SetColor(flashColorID, settings.flashColor);
        sheet.properties.SetFloat(flashIntensityID, settings.flashIntensity);
        sheet.properties.SetColor(blendColorID, settings.blendColor);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}