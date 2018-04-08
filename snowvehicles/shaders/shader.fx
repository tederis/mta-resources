//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
//#define GENERATE_NORMALS
#include "mta-helper.fx"

//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
texture TexMsk;

sampler MaskSampler = sampler_state
{
    Texture = (TexMsk);
};

sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

float3 topVector;
float progress;
float DiffuseColor;

//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
	float dp : TEXCOORD1;
};
 
 
//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
	// Make sure normal is valid
    MTAFixUpNormal( VS.Normal );
 
    //-- Calculate screen pos of vertex
    PS.Position = MTACalcScreenPosition ( VS.Position );
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
 
	float3 WorldNormal = mul(VS.Normal, (float3x3)gWorld);
	
	float dp = dot(topVector,WorldNormal);
   
	PS.dp = dp * progress;
	
	
    //-- Calculate GTA lighting for buildings
    PS.Diffuse = MTACalcGTAVehicleDiffuse( WorldNormal,VS.Diffuse );
 
    return PS;
}
 
//--------------------------------------------------------------------------------------------
//-- PixelShaderFunction
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//--------------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
	float4 texel = tex2D(Sampler0, PS.TexCoord) * PS.Diffuse;
	
	float4 mask = tex2D(MaskSampler, PS.TexCoord);
	
	mask.rgb *= DiffuseColor;
	
	return lerp(texel,mask,PS.dp);
}
 
 
//--------------------------------------------------------------------------------------------
//-- Techniques
//--------------------------------------------------------------------------------------------
technique tec
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
 
//-- Fallback
technique fallback
{
   
}