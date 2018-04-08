texture Tex;
texture noiseTexture;
texture Tex0;

float4x4 lightView;
float4x4 lightProj;

float SparkleSize = 3;
float4 DiffuseColor;

float2 gUVPrePosition = float2( 0, 0 );
float2 gUVScale = float2( 1.0f, 1.0f );                     // UV scale
float2 gUVScaleCenter = float2( 0.5f, 0.5f );
float gUVRotAngle = 0;                   // UV Rotation
float2 gUVRotCenter = float2( 0.5f, 0.5f );
float2 gUVPosition = float2( 0, 0 );              // UV position

#include "tex_matrix.fx"
#include "mta-helper.fx"

sampler TextureSampler = sampler_state
{
    Texture   = (Tex);
};

sampler noiseSampler = sampler_state
{
	Texture = (noiseTexture);
};

sampler Sampler0 = sampler_state
{
    Texture = (Tex0);
};

struct VertexShaderInput
{
	float3 Position : POSITION0;
    //float3 Normal : NORMAL0;
    //float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

struct PixelShaderInput
{
	float4 Position : POSITION0;
	//float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
	float4 TexCoord1	: TEXCOORD1;
};

PixelShaderInput VertexShaderFunction(VertexShaderInput VS)
{
    PixelShaderInput PS = (PixelShaderInput)0;
 
	float4 vertex = float4(VS.Position, 1);
 
	//PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
	
    PS.TexCoord = VS.TexCoord;
	
	PS.TexCoord1 = mul(vertex, gWorld);
    PS.TexCoord1 = mul(PS.TexCoord1, lightView);
    PS.TexCoord1 = mul(PS.TexCoord1, lightProj);
	
	float2 TexCoords;
	TexCoords.x = PS.TexCoord1.x/PS.TexCoord1.w/2.0f + 0.5f;
    TexCoords.y = -PS.TexCoord1.y/PS.TexCoord1.w/2.0f + 0.5f;
	
	if((saturate(TexCoords.x) == TexCoords.x) && (saturate(TexCoords.y) == TexCoords.y))
	{
		float alpha = tex2Dlod(Sampler0, float4(TexCoords.xy, 1, 1)).r;
		if (alpha < 0.5)
			vertex.z += 1;
	}
	
	PS.Position = mul(vertex, gWorldViewProjection);
 
    return PS;
}

float4 PixelShaderFunction(PixelShaderInput PS) : COLOR0
{
	float2 IncomingUVs = PS.TexCoord * SparkleSize;
	float4 TextureMap_6522 = tex2D(noiseSampler, IncomingUVs);
	
	float2 Sparkle2UVs = (IncomingUVs + gCameraDirection.x + gCameraDirection.y + gCameraDirection.z);
	float4 TextureMap_6083 = tex2D(noiseSampler, Sparkle2UVs);
	
	float CustomCode_546 = (TextureMap_6522.r * TextureMap_6083.g) * 1;

	float4 color = tex2D(TextureSampler, PS.TexCoord) + CustomCode_546;
		
    return color * DiffuseColor;
}

float3x3 getTextureTransform()
{
    return makeTextureTransform( gUVPrePosition, gUVScale, gUVScaleCenter, gUVRotAngle, gUVRotCenter, gUVPosition );
}

technique tec0
{
	pass P0
	{
		VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
	}
	
	pass P1
	{
		// Set the UV thingy
        TextureTransform[0] = getTextureTransform();

        // Enable UV thingy
		TextureTransformFlags[0] = Count2;
	}

}

technique fallback
{
    pass P0
    {
		Texture[0] = Tex;
    }
}