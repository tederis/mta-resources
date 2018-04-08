texture Tex;
float4 DiffuseColor;

sampler TextureSampler = sampler_state
{
    Texture   = (Tex);
};

sampler2D InputTexture : register(s0);

float4 main(float2 TexCoords : TEXCOORD0, float4 Diffuse : COLOR0) : COLOR
{
	float4 colorSnow = tex2D( TextureSampler, TexCoords.xy );
	float4 colorDefault = tex2D( InputTexture, TexCoords.xy );
	
	if(Diffuse.g>0.8)
	{
		return ( colorDefault * Diffuse ) * DiffuseColor;
	}
	else
	{
		return ( colorSnow * colorDefault.a ) * DiffuseColor;
	}
}

technique tec0
{
    pass P0
    {
		PixelShader = compile ps_2_0 main();
    }
}

technique fallback
{
    pass P0
    {
        
    }
}

