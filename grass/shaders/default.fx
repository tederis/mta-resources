texture gLevelTex;
float3 vecColor;
float4 		wave; 	// cx,cy,cz,tm
float4 		dir2D; 
float fConst = 1;//1.0f/16384.0f;
float mtrsPerCnl;
float halfEval;


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
sampler SamplerLevel = sampler_state
{
    Texture = (gLevelTex);
};

 
//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float3 Normal : NORMAL0;
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
    float3 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

float 	calc_cyclic 	(float x)				{
	float 	phase 	= 1/(2*3.141592653589f);
	float 	sqrt2	= 1.4142136f;
	float 	sqrt2m2	= 2.8284271f;
	float 	f 	= sqrt2m2*frac(x)-sqrt2;	// [-sqrt2 .. +sqrt2]
	return 	f*f - 1.f;				// [-1     .. +1]
}
float2 	calc_xz_wave 	(float2 dir2D, float frac)		{
	// Beizer
	float2  ctrl_A	= float2(0.f,		0.f	);
	float2 	ctrl_B	= float2(dir2D.x,	dir2D.y	);
	return  lerp	(ctrl_A, ctrl_B, frac);
}
 
//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
 
    float4 pos = float4(VS.Position, 1);

    float3 level = tex2Dlod(SamplerLevel, float4(VS.TexCoord2.xy, 1, 1));
    // Unpack color channels evaluation
    float base = level.r*mtrsPerCnl + level.g*mtrsPerCnl + level.b*mtrsPerCnl - halfEval;
    pos.z = pos.z + base + 0.5f;
    
	float 	dp	= calc_cyclic   (dot(pos,wave));
	float 	H 	= pos.z - base;			// height of vertex (scaled)
	float 	frac 	= (VS.Position.z/1.036f)*fConst;		// fractional
	float 	inten 	= H * dp;
	float2 	result	= calc_xz_wave	(dir2D.xz*inten,frac);
	pos		= float4(pos.x+result.x, pos.y+result.y, pos.z, 1);

    PS.Position = mul(pos, gWorldViewProjection);
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
  
    // Fake lighting
	float 	dpc 	= max 	(0.f, dp);
	PS.Diffuse = vecColor;// * (0.9f*0.25f*dpc*frac);
 
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
	
    return float4(t_base.rgb*PS.Diffuse*2, t_base.a);
}
 
 
//--------------------------------------------------------------------------------------------
//-- Techniques
//--------------------------------------------------------------------------------------------
technique tec
{
    pass P0
    {
        VertexShader = compile vs_3_0 VertexShaderFunction();
        PixelShader = compile ps_3_0 PixelShaderFunction();
    }
}