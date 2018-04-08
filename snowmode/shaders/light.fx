#include "tex_matrix.fx"
#include "mta-helper.fx"

//float3 gCameraDirection : CAMERADIRECTION;
float3 sLightDir = float3(0.507,-0.507,-0.2);
float SparkleSize = 2;


float4 DiffuseColor;
float Alpha = 1.0f;

/*
 *	Snow texture
 */
texture Tex;

sampler TextureSampler = sampler_state
{
    Texture   = (Tex);
};

texture texNormal;
sampler NormalSampler = sampler_state
{
    Texture   = (texNormal);
};

sampler DefaultSampler = sampler_state
{
    Texture   = (gTexture0);
};

/*
 *	Noise texture
 */
texture noiseTexture;

struct VertexShaderInput
{
  float3 Position : POSITION0;
  float3 Normal : NORMAL0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
};

struct PixelShaderInput
{
  float4 Position : POSITION0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
  float2 DistFade : TEXCOORD1;
};

sampler noiseSampler = sampler_state
{
	Texture = (noiseTexture);
};

PixelShaderInput VertexShaderFunction(VertexShaderInput VS)
{
    // Initialize result
    PixelShaderInput PS = (PixelShaderInput)0;

    // Calculate screen pos of vertex
    PS.Position = MTACalcScreenPosition( VS.Position );

    // Pass through tex coord
    PS.TexCoord = VS.TexCoord;

    // Calculate GTA lighting for buildings
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );

    // Distance fade calculation
    float DistanceFromCamera = MTACalcCameraDistance( gCameraPosition, MTACalcWorldPosition( VS.Position ) );
    PS.DistFade.x = 1 - ( ( DistanceFromCamera - sFadeStart ) / ( sFadeEnd - sFadeStart ) );

    // Return result
    return PS;
}

float4 PixelShaderFunction(PixelShaderInput PS) : COLOR0
{
	float4 texel = tex2D(DefaultSampler, PS.TexCoord.xy);

	float4 color = tex2D(TextureSampler, PS.TexCoord.xy);// + CustomCode_546;
		
	color.r = 1;
    return float4(1,0,0,1);
}

technique tec0
{
	pass P0
	{
	    VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}

technique fallback
{
    pass P0
    {
        
    }
}