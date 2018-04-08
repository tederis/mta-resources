float4 L_hemi_color = float4(0.50f,	0.50f,	0.50f, 1.0f);
float3 L_sun_color = float3(1.000f,  0.6f,  0.3f);
float3 L_sun_dir_w = float3(-0.3395f, -0.4226f, -0.8403f);
float3 L_ambient = float3(0.071f,   0.07f,  	0.079f);

//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
#include "mta-helper.fx" 
 
//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    //float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    float2 TexCoord2 : TEXCOORD1;
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
    //float3 WorldPos : TEXCOORD3;
    //float3 c0	: COLOR1;
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
    
    //MTAFixUpNormal( VS.Normal );
 
    //-- Calculate screen pos of vertex
    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
 
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
 
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
    float4	t_base 	= tex2D		(Sampler0,PS.TexCoord);
	float3	final 	= t_base * (L_ambient +  L_hemi_color*0.2f + L_sun_color*0.3f) * 2;
    
    return float4	(final, t_base.a);
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