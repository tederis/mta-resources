//-- These two are set by MTA
texture gDepthBuffer : DEPTHBUFFER;
matrix gProjectionMainScene : PROJECTION_MAIN_SCENE;
 
sampler SamplerDepth = sampler_state
{
    Texture     = (gDepthBuffer);
    AddressU    = Clamp;
    AddressV    = Clamp;
};

float Time;

// From lua script
texture Tex0;
texture Tex1;
texture Tex2;

sampler Sampler0 = sampler_state
{
    Texture     = (Tex0);
};
sampler Sampler1 = sampler_state
{
    Texture     = (Tex1);
};
sampler Sampler2 = sampler_state
{
    Texture     = (Tex2);
};
 
//---------------------------------------------------------------------
// Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
struct PSInput
{
  float4 Position : POSITION0;
  float2 TexCoord0 : TEXCOORD0;
};
 
//-----------------------------------------------------------------------------
//-- Get value from the depth buffer
//-- Uses define set at compile time to handle RAWZ special case (which will use up a few more slots)
//-----------------------------------------------------------------------------
float FetchDepthBufferValue( float2 uv )
{
    float4 texel = tex2D(SamplerDepth, uv);
#if IS_DEPTHBUFFER_RAWZ
    float3 rawval = floor(255.0 * texel.arg + 0.5);
    float3 valueScaler = float3(0.996093809371817670572857294849, 0.0038909914428586627756752238080039, 1.5199185323666651467481343000015e-5);
    return dot(rawval, valueScaler / 255.0);
#else
    return texel.r;
#endif
}
 
//-----------------------------------------------------------------------------
//-- Use the last scene projecion matrix to linearize the depth value a bit more
//-----------------------------------------------------------------------------
float Linearize(float posZ)
{
    return gProjectionMainScene[3][2] / (posZ - gProjectionMainScene[2][2]);
}
 
 
//-----------------------------------------------------------------------------
//-- Name: PS_Example
//-- Type: Pixel shader
//-- Desc: Calculates the pixel color based on texture lookup and interpolated vertex color
//-----------------------------------------------------------------------------
float4 PS_Example( PSInput In ) : COLOR
{
    float BufferValue = FetchDepthBufferValue( In.TexCoord0.xy );
    float Depth = Linearize( BufferValue );
 
    //-- Multiply Depth to get the spread you want
    //Depth *= 0.1f;
	
	float4 ambientColor = float4(0.5f, 0.5f, 0.5f, 1);
	float4 rainColor = float4(0.3f, 0.3f, 0.3f, 0.0f);
	
	float Pi = 3.14f;
	
	float2 SinT = sin(Time * 0.2f * Pi) * 0.5;
	float4 Cosines = float4(cos(SinT), sin(SinT));
	float2 CenteredUV = In.TexCoord0 - float2(0.5f, 0.5f);
	float4 RotatedUV = float4(dot(Cosines.xz*float2(1,-1), CenteredUV)
                         , dot(Cosines.zx, CenteredUV)
                         , dot(Cosines.yw*float2(1,-1), CenteredUV)
                         , dot(Cosines.wy, CenteredUV) ) + 0.5f;
						 
	RotatedUV.y -= Time*2;
	
	float4 rain1 = tex2D(Sampler2, RotatedUV.xy);
	float4 rain2 = tex2D(Sampler2, In.TexCoord0 * 3 - float2(0, Time*2));
	float4 rain = rain1 * rainColor + rain2 * rainColor;
	float4 back2 = tex2D(Sampler0, In.TexCoord0*float2(1, 0.75f) + float2(0, 0.2f));
	float4 subback = back2 * ambientColor;
	
	float4 back = tex2D(Sampler1, In.TexCoord0*float2(1, 0.75f));
	
	float4 finalColor = lerp(subback + rain, back, back.a);
	
	finalColor.a *= Depth/255;
 
    return finalColor;
}
 
 
 
//-----------------------------------------------------------------------------
//-- Techniques
//-----------------------------------------------------------------------------
 
//
//-- Use any readable depthbuffer format
//
technique yes_effect
{
    pass P0
    {
        PixelShader  = compile ps_2_0 PS_Example();
    }
}
 
 
//
//-- If no depthbuffer support, do nothing
//
technique no_effect
{
    pass P0
    {
    }
}