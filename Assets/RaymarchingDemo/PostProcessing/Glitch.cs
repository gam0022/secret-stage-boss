using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(GlitchRenderer), PostProcessEvent.AfterStack, "Custom/Glitch")]
public sealed class Glitch : PostProcessEffectSettings
{
    [Tooltip("Flash Color")] public ColorParameter flashColor = new ColorParameter { value = Color.white };
    [Range(0f, 20f), Tooltip("Flash Intensity")] public FloatParameter flashIntensity = new FloatParameter { value = 0f };
    [Tooltip("Blend Color")] public ColorParameter blendColor = new ColorParameter { value = Color.white };
}
public sealed class GlitchRenderer : PostProcessEffectRenderer<Glitch>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/Custom/Glitch"));
        sheet.properties.SetColor("_FlashColor", settings.flashColor);
        sheet.properties.SetFloat("_FlashIntensity", settings.flashIntensity);
        sheet.properties.SetColor("_BlendColor", settings.blendColor);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}