#pragma header

void main(void)
{
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 texC = texture2D(bitmap, uv);

    vec3 tex = vec3((texC.r + texC.g + texC.b) / 3.0);

    gl_FragColor = vec4(tex, texC.a);
}
