Shader "Noriben/DisplayNumber"
{
	Properties
	{
		_NumTex ("NumTex", 2D) = "white" {}
		_RenderTex ("RenderTex", 2D) = "white" {}
		_Index ("Index", float) = 0
		_IntDigits("Int Digits", int) = 2
		_DecimalDigits("Decimal Digits", int) = 3
		_Test("Test", Range(-100,100)) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue" = "AlphaTest" "DisableBatching" = "True"}
		LOD 100

		Pass
		{
			Cull [_Cull]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _NumTex;
			float4 _NumTex_ST;
			sampler2D _RenderTex;
			float _Test;
			float _Index;
			int _IntDigits;
			int _DecimalDigits;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _NumTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//数値取得
				float4 renderTex = tex2D(_RenderTex, float2((_Index + 0.5) * 0.1, 0.5));

				//表示位置をセンターにオフセット
				i.uv.x += -0.37;

				//カンマの描画
				float left = step(0.076, i.uv.x);
				float right = 1 - step(0.085, i.uv.x);
				float bottom = step(0.0234, i.uv.y);
				float top = 1 - step(0.033, i.uv.y);
				float comma = left * right * top * bottom;

				//数字表示
				//float4 objPos = mul ( unity_ObjectToWorld, float4(0, 0, 0, 1));
				//float minusCheck = renderTex.x;
				float minusCheck = _Test;
				//float minusCheck = -_Time.y; //表示する数値
				float numVal = abs(minusCheck);
	

				fixed4 numCol = fixed4(0,0,0,0);
				float multi, val, com;
				float2 uv = i.uv;
				
				//1未満
				int j = 0;
				for(j = 0; j < _DecimalDigits; j++)
				{
					multi = pow(10, j); 
					val = numVal + 0.00001;//おまじない
					com = val * multi;
					val = frac(com) * 10;
					val = floor(val) * 0.1;

					uv = i.uv;
					uv.y += val; //数字移動
					uv.x -= 0.06 + 0.05 * j; //桁移動
					numCol =  numCol + tex2D(_NumTex, uv);
				}
				
				//1以上
				for(j = 1; j < _IntDigits + 1; j++)
				{
					multi = pow(10, j); 
					val = numVal;
					com = val * 1 / multi;
					val = frac(com) * 10;
					val = floor(val) * 0.1;

					uv = i.uv;
					uv.y += val;
					uv.x += -0.04 + 0.05 * j; 
					numCol =  numCol + tex2D(_NumTex, uv);
				}

				//負号
				float2 muv = i.uv;
				muv.x += -0.005 + 0.05 * (_IntDigits + 1);
				float mleft = step(0.076, muv.x);
				float mright = 1 - step(0.1, muv.x);
				float mbottom = step(0.044, muv.y);
				float mtop = 1 - step(0.054, muv.y);
				float mcol = mleft * mright * mbottom * mtop;
				//0以上のときは負号消す
				if(minusCheck >= 0)
				{
					mcol = 0;
				}
				
				//mix
				fixed4 col = numCol;
				col += float4(comma, comma, comma, 1);
				col += float4(mcol, mcol, mcol, 1);
				col = clamp(col, 0, 0.8); //明るさちょっとさげる
				//使わない部分黒塗り
				top = 1 - step(0.1, i.uv.y);
				float3 black = float3(top, top, top);
				col *= float4(black.xyz, 1);

				//黒部分透明化
				clip(col.x - 0.5);
				return col;
				
			}
			ENDCG
		}
	}
}
