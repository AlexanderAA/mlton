(*
 * OpenGL library implementation
 *)




(*
 * Open GL library interface
 *)
signature GL =
    sig






        type GLreal = Real32.real
        type GLdouble = real

        type GLenum = Word.word
        datatype realspec = realRGB of GLreal * GLreal * GLreal
        type realvertex = GLreal * GLreal * GLreal
        type realrgbacolour = GLreal list

        datatype intspec = intRGB of Word.word * Word.word * Word.word
        type intvertex = Word.word * Word.word * Word.word
        type intrgbacolour = Word.word * Word.word * Word.word * Word.word

        (* Constants *)
        val GL_ACCUM : GLenum
        val GL_LOAD : GLenum
        val GL_RETURN : GLenum
        val GL_MULT : GLenum
        val GL_ADD : GLenum

        (* AlphaFunction *)
        val GL_NEVER : GLenum
        val GL_LESS : GLenum
        val GL_EQUAL : GLenum
        val GL_LEQUAL : GLenum
        val GL_GREATER : GLenum
        val GL_NOTEQUAL : GLenum
        val GL_GEQUAL : GLenum
        val GL_ALWAYS : GLenum

        (* AttribMask *)
        val GL_CURRENT_BIT : GLenum
        val GL_POINT_BIT : GLenum
        val GL_LINE_BIT : GLenum
        val GL_POLYGON_BIT : GLenum
        val GL_POLYGON_STIPPLE_BIT : GLenum
        val GL_PIXEL_MODE_BIT : GLenum
        val GL_LIGHTING_BIT : GLenum
        val GL_FOG_BIT : GLenum
        val GL_DEPTH_BUFFER_BIT : GLenum
        val GL_ACCUM_BUFFER_BIT : GLenum
        val GL_STENCIL_BUFFER_BIT : GLenum
        val GL_VIEWPORT_BIT : GLenum
        val GL_TRANSFORM_BIT : GLenum
        val GL_ENABLE_BIT : GLenum
        val GL_COLOR_BUFFER_BIT : GLenum
        val GL_HINT_BIT : GLenum
        val GL_EVAL_BIT : GLenum
        val GL_LIST_BIT : GLenum
        val GL_TEXTURE_BIT : GLenum
        val GL_SCISSOR_BIT : GLenum
        val GL_ALL_ATTRIB_BITS : GLenum

        (* BeginMode *)
        val GL_POINTS : GLenum
        val GL_LINES : GLenum
        val GL_LINE_LOOP : GLenum
        val GL_LINE_STRIP : GLenum
        val GL_TRIANGLES : GLenum
        val GL_TRIANGLE_STRIP : GLenum
        val GL_TRIANGLE_FAN : GLenum
        val GL_QUADS : GLenum
        val GL_QUAD_STRIP : GLenum
        val GL_POLYGON : GLenum

        (* BlendingFactorDest *)
        val GL_ZERO : GLenum
        val GL_ONE : GLenum
        val GL_SRC_COLOR : GLenum
        val GL_ONE_MINUS_SRC_COLOR : GLenum
        val GL_SRC_ALPHA : GLenum
        val GL_ONE_MINUS_SRC_ALPHA : GLenum
        val GL_DST_ALPHA : GLenum
        val GL_ONE_MINUS_DST_ALPHA : GLenum

        (* BlendingFactorSrc *)
        val GL_DST_COLOR : GLenum
        val GL_ONE_MINUS_DST_COLOR : GLenum
        val GL_SRC_ALPHA_SATURATE : GLenum

        (* Boolean *)
        val GL_TRUE : GLenum
        val GL_FALSE : GLenum

        (* ClipPlaneName *)
        val GL_CLIP_PLANE0 : GLenum
        val GL_CLIP_PLANE1 : GLenum
        val GL_CLIP_PLANE2 : GLenum
        val GL_CLIP_PLANE3 : GLenum
        val GL_CLIP_PLANE4 : GLenum
        val GL_CLIP_PLANE5 : GLenum

        (* ColorMaterialFace *)
        (* DataType *)
        val GL_BYTE : GLenum
        val GL_UNSIGNED_BYTE : GLenum
        val GL_SHORT : GLenum
        val GL_UNSIGNED_SHORT : GLenum
        val GL_INT : GLenum
        val GL_UNSIGNED_INT : GLenum
        val GL_FLOAT : GLenum
        val GL_2_BYTES : GLenum
        val GL_3_BYTES : GLenum
        val GL_4_BYTES : GLenum
        val GL_DOUBLE : GLenum

        (* DrawBufferMode *)
        val GL_NONE : GLenum
        val GL_FRONT_LEFT : GLenum
        val GL_FRONT_RIGHT : GLenum
        val GL_BACK_LEFT : GLenum
        val GL_BACK_RIGHT : GLenum
        val GL_FRONT : GLenum
        val GL_BACK : GLenum
        val GL_LEFT : GLenum
        val GL_RIGHT : GLenum
        val GL_FRONT_AND_BACK : GLenum
        val GL_AUX0 : GLenum
        val GL_AUX1 : GLenum
        val GL_AUX2 : GLenum
        val GL_AUX3 : GLenum

        (* ErrorCode *)
        val GL_NO_ERROR : GLenum
        val GL_INVALID_ENUM : GLenum
        val GL_INVALID_VALUE : GLenum
        val GL_INVALID_OPERATION : GLenum
        val GL_STACK_OVERFLOW : GLenum
        val GL_STACK_UNDERFLOW : GLenum
        val GL_OUT_OF_MEMORY : GLenum

        (* FeedBackMode *)
        val GL_2D : GLenum
        val GL_3D : GLenum
        val GL_3D_COLOR : GLenum
        val GL_3D_COLOR_TEXTURE : GLenum
        val GL_4D_COLOR_TEXTURE : GLenum

        (* FeedBackToken *)
        val GL_PASS_THROUGH_TOKEN : GLenum
        val GL_POINT_TOKEN : GLenum
        val GL_LINE_TOKEN : GLenum
        val GL_POLYGON_TOKEN : GLenum
        val GL_BITMAP_TOKEN : GLenum
        val GL_DRAW_PIXEL_TOKEN : GLenum
        val GL_COPY_PIXEL_TOKEN : GLenum
        val GL_LINE_RESET_TOKEN : GLenum

        (* FogMode *)
        val GL_EXP : GLenum
        val GL_EXP2 : GLenum

        (* FrontFaceDirection *)
        val GL_CW : GLenum
        val GL_CCW : GLenum

        (* GetMapTarget *)
        val GL_COEFF : GLenum
        val GL_ORDER : GLenum
        val GL_DOMAIN : GLenum

        val GL_CURRENT_COLOR : GLenum
        val GL_CURRENT_INDEX : GLenum
        val GL_CURRENT_NORMAL : GLenum
        val GL_CURRENT_TEXTURE_COORDS : GLenum
        val GL_CURRENT_RASTER_COLOR : GLenum
        val GL_CURRENT_RASTER_INDEX : GLenum
        val GL_CURRENT_RASTER_TEXTURE_COORDS : GLenum
        val GL_CURRENT_RASTER_POSITION : GLenum
        val GL_CURRENT_RASTER_POSITION_VALID : GLenum
        val GL_CURRENT_RASTER_DISTANCE : GLenum
        val GL_POINT_SMOOTH : GLenum
        val GL_POINT_SIZE : GLenum
        val GL_POINT_SIZE_RANGE : GLenum
        val GL_POINT_SIZE_GRANULARITY : GLenum
        val GL_LINE_SMOOTH : GLenum
        val GL_LINE_WIDTH : GLenum
        val GL_LINE_WIDTH_RANGE : GLenum
        val GL_LINE_WIDTH_GRANULARITY : GLenum
        val GL_LINE_STIPPLE : GLenum
        val GL_LINE_STIPPLE_PATTERN : GLenum
        val GL_LINE_STIPPLE_REPEAT : GLenum
        val GL_LIST_MODE : GLenum
        val GL_MAX_LIST_NESTING : GLenum
        val GL_LIST_BASE : GLenum
        val GL_LIST_INDEX : GLenum
        val GL_POLYGON_MODE : GLenum
        val GL_POLYGON_SMOOTH : GLenum
        val GL_POLYGON_STIPPLE : GLenum
        val GL_EDGE_FLAG : GLenum
        val GL_CULL_FACE : GLenum
        val GL_CULL_FACE_MODE : GLenum
        val GL_FRONT_FACE : GLenum
        val GL_LIGHTING : GLenum
        val GL_LIGHT_MODEL_LOCAL_VIEWER : GLenum
        val GL_LIGHT_MODEL_TWO_SIDE : GLenum
        val GL_LIGHT_MODEL_AMBIENT : GLenum
        val GL_SHADE_MODEL : GLenum
        val GL_COLOR_MATERIAL_FACE : GLenum
        val GL_COLOR_MATERIAL_PARAMETER : GLenum
        val GL_COLOR_MATERIAL : GLenum
        val GL_FOG : GLenum
        val GL_FOG_INDEX : GLenum
        val GL_FOG_DENSITY : GLenum
        val GL_FOG_START : GLenum
        val GL_FOG_END : GLenum
        val GL_FOG_MODE : GLenum
        val GL_FOG_COLOR : GLenum
        val GL_DEPTH_RANGE : GLenum
        val GL_DEPTH_TEST : GLenum
        val GL_DEPTH_WRITEMASK : GLenum
        val GL_DEPTH_CLEAR_VALUE : GLenum
        val GL_DEPTH_FUNC : GLenum
        val GL_ACCUM_CLEAR_VALUE : GLenum
        val GL_STENCIL_TEST : GLenum
        val GL_STENCIL_CLEAR_VALUE : GLenum
        val GL_STENCIL_FUNC : GLenum
        val GL_STENCIL_VALUE_MASK : GLenum
        val GL_STENCIL_FAIL : GLenum
        val GL_STENCIL_PASS_DEPTH_FAIL : GLenum
        val GL_STENCIL_PASS_DEPTH_PASS : GLenum
        val GL_STENCIL_REF : GLenum
        val GL_STENCIL_WRITEMASK : GLenum
        val GL_MATRIX_MODE : GLenum
        val GL_NORMALIZE : GLenum
        val GL_VIEWPORT : GLenum
        val GL_MODELVIEW_STACK_DEPTH : GLenum
        val GL_PROJECTION_STACK_DEPTH : GLenum
        val GL_TEXTURE_STACK_DEPTH : GLenum
        val GL_MODELVIEW_MATRIX : GLenum
        val GL_PROJECTION_MATRIX : GLenum
        val GL_TEXTURE_MATRIX : GLenum
        val GL_ATTRIB_STACK_DEPTH : GLenum
        val GL_CLIENT_ATTRIB_STACK_DEPTH : GLenum
        val GL_ALPHA_TEST : GLenum
        val GL_ALPHA_TEST_FUNC : GLenum
        val GL_ALPHA_TEST_REF : GLenum
        val GL_DITHER : GLenum
        val GL_BLEND_DST : GLenum
        val GL_BLEND_SRC : GLenum
        val GL_BLEND : GLenum
        val GL_LOGIC_OP_MODE : GLenum
        val GL_INDEX_LOGIC_OP : GLenum
        val GL_COLOR_LOGIC_OP : GLenum
        val GL_AUX_BUFFERS : GLenum
        val GL_DRAW_BUFFER : GLenum
        val GL_READ_BUFFER : GLenum
        val GL_SCISSOR_BOX : GLenum
        val GL_SCISSOR_TEST : GLenum
        val GL_INDEX_CLEAR_VALUE : GLenum
        val GL_INDEX_WRITEMASK : GLenum
        val GL_COLOR_CLEAR_VALUE : GLenum
        val GL_COLOR_WRITEMASK : GLenum
        val GL_INDEX_MODE : GLenum
        val GL_RGBA_MODE : GLenum
        val GL_DOUBLEBUFFER : GLenum
        val GL_STEREO : GLenum
        val GL_RENDER_MODE : GLenum
        val GL_PERSPECTIVE_CORRECTION_HINT : GLenum
        val GL_POINT_SMOOTH_HINT : GLenum
        val GL_LINE_SMOOTH_HINT : GLenum
        val GL_POLYGON_SMOOTH_HINT : GLenum
        val GL_FOG_HINT : GLenum
        val GL_TEXTURE_GEN_S : GLenum
        val GL_TEXTURE_GEN_T : GLenum
        val GL_TEXTURE_GEN_R : GLenum
        val GL_TEXTURE_GEN_Q : GLenum
        val GL_PIXEL_MAP_I_TO_I : GLenum
        val GL_PIXEL_MAP_S_TO_S : GLenum
        val GL_PIXEL_MAP_I_TO_R : GLenum
        val GL_PIXEL_MAP_I_TO_G : GLenum
        val GL_PIXEL_MAP_I_TO_B : GLenum
        val GL_PIXEL_MAP_I_TO_A : GLenum
        val GL_PIXEL_MAP_R_TO_R : GLenum
        val GL_PIXEL_MAP_G_TO_G : GLenum
        val GL_PIXEL_MAP_B_TO_B : GLenum
        val GL_PIXEL_MAP_A_TO_A : GLenum
        val GL_PIXEL_MAP_I_TO_I_SIZE : GLenum
        val GL_PIXEL_MAP_S_TO_S_SIZE : GLenum
        val GL_PIXEL_MAP_I_TO_R_SIZE : GLenum
        val GL_PIXEL_MAP_I_TO_G_SIZE : GLenum
        val GL_PIXEL_MAP_I_TO_B_SIZE : GLenum
        val GL_PIXEL_MAP_I_TO_A_SIZE : GLenum
        val GL_PIXEL_MAP_R_TO_R_SIZE : GLenum
        val GL_PIXEL_MAP_G_TO_G_SIZE : GLenum
        val GL_PIXEL_MAP_B_TO_B_SIZE : GLenum
        val GL_PIXEL_MAP_A_TO_A_SIZE : GLenum
        val GL_UNPACK_SWAP_BYTES : GLenum
        val GL_UNPACK_LSB_FIRST : GLenum
        val GL_UNPACK_ROW_LENGTH : GLenum
        val GL_UNPACK_SKIP_ROWS : GLenum
        val GL_UNPACK_SKIP_PIXELS : GLenum
        val GL_UNPACK_ALIGNMENT : GLenum
        val GL_PACK_SWAP_BYTES : GLenum
        val GL_PACK_LSB_FIRST : GLenum
        val GL_PACK_ROW_LENGTH : GLenum
        val GL_PACK_SKIP_ROWS : GLenum
        val GL_PACK_SKIP_PIXELS : GLenum
        val GL_PACK_ALIGNMENT : GLenum
        val GL_MAP_COLOR : GLenum
        val GL_MAP_STENCIL : GLenum
        val GL_INDEX_SHIFT : GLenum
        val GL_INDEX_OFFSET : GLenum
        val GL_RED_SCALE : GLenum
        val GL_RED_BIAS : GLenum
        val GL_ZOOM_X : GLenum
        val GL_ZOOM_Y : GLenum
        val GL_GREEN_SCALE : GLenum
        val GL_GREEN_BIAS : GLenum
        val GL_BLUE_SCALE : GLenum
        val GL_BLUE_BIAS : GLenum
        val GL_ALPHA_SCALE : GLenum
        val GL_ALPHA_BIAS : GLenum
        val GL_DEPTH_SCALE : GLenum
        val GL_DEPTH_BIAS : GLenum
        val GL_MAX_EVAL_ORDER : GLenum
        val GL_MAX_LIGHTS : GLenum
        val GL_MAX_CLIP_PLANES : GLenum
        val GL_MAX_TEXTURE_SIZE : GLenum
        val GL_MAX_PIXEL_MAP_TABLE : GLenum
        val GL_MAX_ATTRIB_STACK_DEPTH : GLenum
        val GL_MAX_MODELVIEW_STACK_DEPTH : GLenum
        val GL_MAX_NAME_STACK_DEPTH : GLenum
        val GL_MAX_PROJECTION_STACK_DEPTH : GLenum
        val GL_MAX_TEXTURE_STACK_DEPTH : GLenum
        val GL_MAX_VIEWPORT_DIMS : GLenum
        val GL_MAX_CLIENT_ATTRIB_STACK_DEPTH : GLenum
        val GL_SUBPIXEL_BITS : GLenum
        val GL_INDEX_BITS : GLenum
        val GL_RED_BITS : GLenum
        val GL_GREEN_BITS : GLenum
        val GL_BLUE_BITS : GLenum
        val GL_ALPHA_BITS : GLenum
        val GL_DEPTH_BITS : GLenum
        val GL_STENCIL_BITS : GLenum
        val GL_ACCUM_RED_BITS : GLenum
        val GL_ACCUM_GREEN_BITS : GLenum
        val GL_ACCUM_BLUE_BITS : GLenum
        val GL_ACCUM_ALPHA_BITS : GLenum
        val GL_NAME_STACK_DEPTH : GLenum
        val GL_AUTO_NORMAL : GLenum
        val GL_MAP1_COLOR_4 : GLenum
        val GL_MAP1_INDEX : GLenum
        val GL_MAP1_NORMAL : GLenum
        val GL_MAP1_TEXTURE_COORD_1 : GLenum
        val GL_MAP1_TEXTURE_COORD_2 : GLenum
        val GL_MAP1_TEXTURE_COORD_3 : GLenum
        val GL_MAP1_TEXTURE_COORD_4 : GLenum
        val GL_MAP1_VERTEX_3 : GLenum
        val GL_MAP1_VERTEX_4 : GLenum
        val GL_MAP2_COLOR_4 : GLenum
        val GL_MAP2_INDEX : GLenum
        val GL_MAP2_NORMAL : GLenum
        val GL_MAP2_TEXTURE_COORD_1 : GLenum
        val GL_MAP2_TEXTURE_COORD_2 : GLenum
        val GL_MAP2_TEXTURE_COORD_3 : GLenum
        val GL_MAP2_TEXTURE_COORD_4 : GLenum
        val GL_MAP2_VERTEX_3 : GLenum
        val GL_MAP2_VERTEX_4 : GLenum
        val GL_MAP1_GRID_DOMAIN : GLenum
        val GL_MAP1_GRID_SEGMENTS : GLenum
        val GL_MAP2_GRID_DOMAIN : GLenum
        val GL_MAP2_GRID_SEGMENTS : GLenum
        val GL_TEXTURE_1D : GLenum
        val GL_TEXTURE_2D : GLenum
        val GL_FEEDBACK_BUFFER_POINTER : GLenum
        val GL_FEEDBACK_BUFFER_SIZE : GLenum
        val GL_FEEDBACK_BUFFER_TYPE : GLenum
        val GL_SELECTION_BUFFER_POINTER : GLenum
        val GL_SELECTION_BUFFER_SIZE : GLenum

        (* GetTextureParameter *)
        val GL_TEXTURE_WIDTH : GLenum
        val GL_TEXTURE_HEIGHT : GLenum
        val GL_TEXTURE_INTERNAL_FORMAT : GLenum
        val GL_TEXTURE_BORDER_COLOR : GLenum
        val GL_TEXTURE_BORDER : GLenum

        (* HGLenumMode *)
        val GL_DONT_CARE : GLenum
        val GL_FASTEST : GLenum
        val GL_NICEST : GLenum

        (* LightName *)
        val GL_LIGHT0 : GLenum
        val GL_LIGHT1 : GLenum
        val GL_LIGHT2 : GLenum
        val GL_LIGHT3 : GLenum
        val GL_LIGHT4 : GLenum
        val GL_LIGHT5 : GLenum
        val GL_LIGHT6 : GLenum
        val GL_LIGHT7 : GLenum

        (* LightParameter *)
        val GL_AMBIENT : GLenum
        val GL_DIFFUSE : GLenum
        val GL_SPECULAR : GLenum
        val GL_POSITION : GLenum
        val GL_SPOT_DIRECTION : GLenum
        val GL_SPOT_EXPONENT : GLenum
        val GL_SPOT_CUTOFF : GLenum
        val GL_CONSTANT_ATTENUATION : GLenum
        val GL_LINEAR_ATTENUATION : GLenum
        val GL_QUADRATIC_ATTENUATION : GLenum

        (* ListMode *)
        val GL_COMPILE : GLenum
        val GL_COMPILE_AND_EXECUTE : GLenum

        (* LogicOp *)
        val GL_CLEAR : GLenum
        val GL_AND : GLenum
        val GL_AND_REVERSE : GLenum
        val GL_COPY : GLenum
        val GL_AND_INVERTED : GLenum
        val GL_NOOP : GLenum
        val GL_XOR : GLenum
        val GL_OR : GLenum
        val GL_NOR : GLenum
        val GL_EQUIV : GLenum
        val GL_INVERT : GLenum
        val GL_OR_REVERSE : GLenum
        val GL_COPY_INVERTED : GLenum
        val GL_OR_INVERTED : GLenum
        val GL_NAND : GLenum
        val GL_SET : GLenum

        (* MaterialParameter *)
        val GL_EMISSION : GLenum
        val GL_SHININESS : GLenum
        val GL_AMBIENT_AND_DIFFUSE : GLenum
        val GL_COLOR_INDEXES : GLenum

        (* MatrixMode *)
        val GL_MODELVIEW : GLenum
        val GL_PROJECTION : GLenum
        val GL_TEXTURE : GLenum

        (* PixelCopyType *)
        val GL_COLOR : GLenum
        val GL_DEPTH : GLenum
        val GL_STENCIL : GLenum

        (* PixelFormat *)
        val GL_COLOR_INDEX : GLenum
        val GL_STENCIL_INDEX : GLenum
        val GL_DEPTH_COMPONENT : GLenum
        val GL_RED : GLenum
        val GL_GREEN : GLenum
        val GL_BLUE : GLenum
        val GL_ALPHA : GLenum
        val GL_RGB : GLenum
        val GL_RGBA : GLenum
        val GL_LUMINANCE : GLenum
        val GL_LUMINANCE_ALPHA : GLenum

        (* PixelType *)
        val GL_BITMAP : GLenum

        (* PolygonMode *)
        val GL_POINT : GLenum
        val GL_LINE : GLenum
        val GL_FILL : GLenum

        (* RenderingMode *)
        val GL_RENDER : GLenum
        val GL_FEEDBACK : GLenum
        val GL_SELECT : GLenum

        (* ShadingModel *)
        val GL_FLAT : GLenum
        val GL_SMOOTH : GLenum

        (* StencilOp *)
        val GL_KEEP : GLenum
        val GL_REPLACE : GLenum
        val GL_INCR : GLenum
        val GL_DECR : GLenum

        (* StringName *)
        val GL_VENDOR : GLenum
        val GL_RENDERER : GLenum
        val GL_VERSION : GLenum
        val GL_EXTENSIONS : GLenum

        (* TextureCoordName *)
        val GL_S : GLenum
        val GL_T : GLenum
        val GL_R : GLenum
        val GL_Q : GLenum

        (* TextureEnvMode *)
        val GL_MODULATE : GLenum
        val GL_DECAL : GLenum

        (* TextureEnvParameter *)
        val GL_TEXTURE_ENV_MODE : GLenum
        val GL_TEXTURE_ENV_COLOR : GLenum

        (* TextureEnvTarget *)
        val GL_TEXTURE_ENV : GLenum

        (* TextureGenMode *)
        val GL_EYE_LINEAR : GLenum
        val GL_OBJECT_LINEAR : GLenum
        val GL_SPHERE_MAP : GLenum

        (* TextureGenParameter *)
        val GL_TEXTURE_GEN_MODE : GLenum
        val GL_OBJECT_PLANE : GLenum
        val GL_EYE_PLANE : GLenum

        (* TextureMagFilter *)
        val GL_NEAREST : GLenum
        val GL_LINEAR : GLenum

        (* TextureMinFilter *)
        val GL_NEAREST_MIPMAP_NEAREST : GLenum
        val GL_LINEAR_MIPMAP_NEAREST : GLenum
        val GL_NEAREST_MIPMAP_LINEAR : GLenum
        val GL_LINEAR_MIPMAP_LINEAR : GLenum

        (* TextureParameterName *)
        val GL_TEXTURE_MAG_FILTER : GLenum
        val GL_TEXTURE_MIN_FILTER : GLenum
        val GL_TEXTURE_WRAP_S : GLenum
        val GL_TEXTURE_WRAP_T : GLenum

        (* TextureWrapMode *)
        val GL_CLAMP : GLenum
        val GL_REPEAT : GLenum

        (* ClientAttribMask *)
        val GL_CLIENT_PIXEL_STORE_BIT : GLenum
        val GL_CLIENT_VERTEX_ARRAY_BIT : GLenum
        val GL_CLIENT_ALL_ATTRIB_BITS : Word8Vector.vector

        (* polygon_offset *)
        val GL_POLYGON_OFFSET_FACTOR : GLenum
        val GL_POLYGON_OFFSET_UNITS : GLenum
        val GL_POLYGON_OFFSET_POINT : GLenum
        val GL_POLYGON_OFFSET_LINE : GLenum
        val GL_POLYGON_OFFSET_FILL : GLenum

        (* texture *)
        val GL_ALPHA4 : GLenum
        val GL_ALPHA8 : GLenum
        val GL_ALPHA12 : GLenum
        val GL_ALPHA16 : GLenum
        val GL_LUMINANCE4 : GLenum
        val GL_LUMINANCE8 : GLenum
        val GL_LUMINANCE12 : GLenum
        val GL_LUMINANCE16 : GLenum
        val GL_LUMINANCE4_ALPHA4 : GLenum
        val GL_LUMINANCE6_ALPHA2 : GLenum
        val GL_LUMINANCE8_ALPHA8 : GLenum
        val GL_LUMINANCE12_ALPHA4 : GLenum
        val GL_LUMINANCE12_ALPHA12 : GLenum
        val GL_LUMINANCE16_ALPHA16 : GLenum
        val GL_INTENSITY : GLenum
        val GL_INTENSITY4 : GLenum
        val GL_INTENSITY8 : GLenum
        val GL_INTENSITY12 : GLenum
        val GL_INTENSITY16 : GLenum
        val GL_R3_G3_B2 : GLenum
        val GL_RGB4 : GLenum
        val GL_RGB5 : GLenum
        val GL_RGB8 : GLenum
        val GL_RGB10 : GLenum
        val GL_RGB12 : GLenum
        val GL_RGB16 : GLenum
        val GL_RGBA2 : GLenum
        val GL_RGBA4 : GLenum
        val GL_RGB5_A1 : GLenum
        val GL_RGBA8 : GLenum
        val GL_RGB10_A2 : GLenum
        val GL_RGBA12 : GLenum
        val GL_RGBA16 : GLenum
        val GL_TEXTURE_RED_SIZE : GLenum
        val GL_TEXTURE_GREEN_SIZE : GLenum
        val GL_TEXTURE_BLUE_SIZE : GLenum
        val GL_TEXTURE_ALPHA_SIZE : GLenum
        val GL_TEXTURE_LUMINANCE_SIZE : GLenum
        val GL_TEXTURE_INTENSITY_SIZE : GLenum
        val GL_PROXY_TEXTURE_1D : GLenum
        val GL_PROXY_TEXTURE_2D : GLenum

        (* texture_object *)
        val GL_TEXTURE_PRIORITY : GLenum
        val GL_TEXTURE_RESIDENT : GLenum
        val GL_TEXTURE_BINDING_1D : GLenum
        val GL_TEXTURE_BINDING_2D : GLenum

        (* vertex_array *)
        val GL_VERTEX_ARRAY : GLenum
        val GL_NORMAL_ARRAY : GLenum
        val GL_COLOR_ARRAY : GLenum
        val GL_INDEX_ARRAY : GLenum
        val GL_TEXTURE_COORD_ARRAY : GLenum
        val GL_EDGE_FLAG_ARRAY : GLenum
        val GL_VERTEX_ARRAY_SIZE : GLenum
        val GL_VERTEX_ARRAY_TYPE : GLenum
        val GL_VERTEX_ARRAY_STRIDE : GLenum
        val GL_NORMAL_ARRAY_TYPE : GLenum
        val GL_NORMAL_ARRAY_STRIDE : GLenum
        val GL_COLOR_ARRAY_SIZE : GLenum
        val GL_COLOR_ARRAY_TYPE : GLenum
        val GL_COLOR_ARRAY_STRIDE : GLenum
        val GL_INDEX_ARRAY_TYPE : GLenum
        val GL_INDEX_ARRAY_STRIDE : GLenum
        val GL_TEXTURE_COORD_ARRAY_SIZE : GLenum
        val GL_TEXTURE_COORD_ARRAY_TYPE : GLenum
        val GL_TEXTURE_COORD_ARRAY_STRIDE : GLenum
        val GL_EDGE_FLAG_ARRAY_STRIDE : GLenum
        val GL_VERTEX_ARRAY_POINTER : GLenum
        val GL_NORMAL_ARRAY_POINTER : GLenum
        val GL_COLOR_ARRAY_POINTER : GLenum
        val GL_INDEX_ARRAY_POINTER : GLenum
        val GL_TEXTURE_COORD_ARRAY_POINTER : GLenum
        val GL_EDGE_FLAG_ARRAY_POINTER : GLenum
        val GL_V2F : GLenum
        val GL_V3F : GLenum
        val GL_C4UB_V2F : GLenum
        val GL_C4UB_V3F : GLenum
        val GL_C3F_V3F : GLenum
        val GL_N3F_V3F : GLenum
        val GL_C4F_N3F_V3F : GLenum
        val GL_T2F_V3F : GLenum
        val GL_T4F_V4F : GLenum
        val GL_T2F_C4UB_V3F : GLenum
        val GL_T2F_C3F_V3F : GLenum
        val GL_T2F_N3F_V3F : GLenum
        val GL_T2F_C4F_N3F_V3F : GLenum
        val GL_T4F_C4F_N3F_V4F : GLenum

        (* Extensions *)
        val GL_EXT_vertex_array : GLenum
        val GL_WIN_swap_hint : GLenum
        val GL_EXT_bgra : GLenum
        val GL_EXT_paletted_texture : GLenum

        (* EXT_vertex_array *)
        val GL_VERTEX_ARRAY_EXT : GLenum
        val GL_NORMAL_ARRAY_EXT : GLenum
        val GL_COLOR_ARRAY_EXT : GLenum
        val GL_INDEX_ARRAY_EXT : GLenum
        val GL_TEXTURE_COORD_ARRAY_EXT : GLenum
        val GL_EDGE_FLAG_ARRAY_EXT : GLenum
        val GL_VERTEX_ARRAY_SIZE_EXT : GLenum
        val GL_VERTEX_ARRAY_TYPE_EXT : GLenum
        val GL_VERTEX_ARRAY_STRIDE_EXT : GLenum
        val GL_VERTEX_ARRAY_COUNT_EXT : GLenum
        val GL_NORMAL_ARRAY_TYPE_EXT : GLenum
        val GL_NORMAL_ARRAY_STRIDE_EXT : GLenum
        val GL_NORMAL_ARRAY_COUNT_EXT : GLenum
        val GL_COLOR_ARRAY_SIZE_EXT : GLenum
        val GL_COLOR_ARRAY_TYPE_EXT : GLenum
        val GL_COLOR_ARRAY_STRIDE_EXT : GLenum
        val GL_COLOR_ARRAY_COUNT_EXT : GLenum
        val GL_INDEX_ARRAY_TYPE_EXT : GLenum
        val GL_INDEX_ARRAY_STRIDE_EXT : GLenum
        val GL_INDEX_ARRAY_COUNT_EXT : GLenum
        val GL_TEXTURE_COORD_ARRAY_SIZE_EXT : GLenum
        val GL_TEXTURE_COORD_ARRAY_TYPE_EXT : GLenum
        val GL_TEXTURE_COORD_ARRAY_STRIDE_EXT : GLenum
        val GL_TEXTURE_COORD_ARRAY_COUNT_EXT : GLenum
        val GL_EDGE_FLAG_ARRAY_STRIDE_EXT : GLenum
        val GL_EDGE_FLAG_ARRAY_COUNT_EXT : GLenum
        val GL_VERTEX_ARRAY_POINTER_EXT : GLenum
        val GL_NORMAL_ARRAY_POINTER_EXT : GLenum
        val GL_COLOR_ARRAY_POINTER_EXT : GLenum
        val GL_INDEX_ARRAY_POINTER_EXT : GLenum
        val GL_TEXTURE_COORD_ARRAY_POINTER_EXT : GLenum
        val GL_EDGE_FLAG_ARRAY_POINTER_EXT : GLenum
        val GL_DOUBLE_EXT : GLenum

        (* EXT_bgra *)
        val GL_BGR_EXT : GLenum
        val GL_BGRA_EXT : GLenum

        (* EXT_paletted_texture *)
        (* These must match the GL_COLOR_TABLE_*_SGI enumerants *)
        val GL_COLOR_TABLE_FORMAT_EXT : GLenum
        val GL_COLOR_TABLE_WIDTH_EXT : GLenum
        val GL_COLOR_TABLE_RED_SIZE_EXT : GLenum
        val GL_COLOR_TABLE_GREEN_SIZE_EXT : GLenum
        val GL_COLOR_TABLE_BLUE_SIZE_EXT : GLenum
        val GL_COLOR_TABLE_ALPHA_SIZE_EXT : GLenum
        val GL_COLOR_TABLE_LUMINANCE_SIZE_EXT : GLenum
        val GL_COLOR_TABLE_INTENSITY_SIZE_EXT : GLenum

        val GL_COLOR_INDEX1_EXT : GLenum
        val GL_COLOR_INDEX2_EXT : GLenum
        val GL_COLOR_INDEX4_EXT : GLenum
        val GL_COLOR_INDEX8_EXT : GLenum
        val GL_COLOR_INDEX12_EXT : GLenum
        val GL_COLOR_INDEX16_EXT : GLenum

        (* For compatibility with OpenGL v1.0 *)
        val GL_LOGIC_OP : GLenum
        val GL_TEXTURE_COMPONENTS : GLenum
        val c_glBegin : GLenum -> unit
        val glBegin : GLenum -> unit

        val c_glBlendFunc : GLenum * GLenum -> unit
        val glBlendFunc : GLenum -> GLenum -> unit

        val c_glCallList : int -> unit
        val glCallList : int -> unit

        val c_glClearColor: GLreal * GLreal * GLreal * GLreal -> unit
        val glClearColor: GLreal -> GLreal -> GLreal -> GLreal -> unit

        val c_glClearDepth : GLreal -> unit
        val glClearDepth : GLreal -> unit

        val c_glColor3d : GLdouble * GLdouble * GLdouble -> unit
        val glColor3d : GLdouble -> GLdouble -> GLdouble -> unit

        val c_glColor3f : GLreal * GLreal * GLreal -> unit
        val glColor3f : GLreal -> GLreal -> GLreal -> unit

        val c_glColor3ub : Word8.word * Word8.word * Word8.word -> unit
        val glColor3ub : Word8.word -> Word8.word -> Word8.word -> unit

        val c_glColor4d : GLdouble * GLdouble * GLdouble * GLdouble -> unit
        val glColor4d : GLdouble -> GLdouble -> GLdouble -> GLdouble -> unit

        val c_glColor4f : GLreal * GLreal * GLreal * GLreal -> unit
        val glColor4f : GLreal -> GLreal -> GLreal -> GLreal -> unit

        val c_glColor4ub : Word8.word * Word8.word * Word8.word * Word8.word -> unit
        val glColor4ub : Word8.word -> Word8.word -> Word8.word -> Word8.word -> unit

        val c_glColorMaterial : GLenum * GLenum -> unit
        val glColorMaterial : GLenum -> GLenum -> unit

        val c_glDisable : GLenum -> unit
        val glDisable : GLenum -> unit

        val c_glEnable : GLenum -> unit
        val glEnable : GLenum -> unit

        val c_glEnd : unit -> unit
        val glEnd : unit -> unit

        val c_glEndList : unit -> unit
        val glEndList : unit -> unit

        val c_glRasterPos2i : int * int -> unit
        val glRasterPos2i : int -> int -> unit

        val c_glRasterPos2f : GLreal * GLreal -> unit
        val glRasterPos2f : GLreal -> GLreal -> unit

        val c_glRasterPos2d : GLdouble * GLdouble -> unit
        val glRasterPos2d : GLdouble -> GLdouble -> unit

        val c_glClear: GLenum -> unit
        val glClear: GLenum -> unit

        val c_glFlush: unit -> unit
        val glFlush: unit -> unit

        val c_glFrontFace : GLenum -> unit
        val glFrontFace : GLenum -> unit

        val c_glLightfv : GLenum * GLenum * GLreal array -> unit
        val glLightfv : GLenum -> GLenum -> realrgbacolour -> unit

        val c_glLightModelfv : GLenum * GLreal array -> unit
        val glLightModelfv : GLenum -> realrgbacolour -> unit

        val c_glLineWidth : GLreal -> unit
        val glLineWidth : GLreal -> unit

        val c_glLoadIdentity : unit -> unit
        val glLoadIdentity : unit -> unit

        val c_glMaterialfv : GLenum * GLenum * GLreal array -> unit
        val glMaterialfv : GLenum -> GLenum -> GLreal array -> unit

        val c_glMatrixMode : GLenum -> unit
        val glMatrixMode : GLenum -> unit

        val c_glNewList : int * GLenum -> unit
        val glNewList : int -> GLenum -> unit

        val c_glOrtho : GLdouble * GLdouble * GLdouble * GLdouble * GLdouble * GLdouble -> unit
        val glOrtho : GLdouble -> GLdouble -> GLdouble -> GLdouble -> GLdouble -> GLdouble -> unit

        val c_glPushMatrix : unit -> unit
        val glPushMatrix : unit -> unit

        val c_glTranslated : GLdouble * GLdouble * GLdouble -> unit
        val glTranslated : GLdouble -> GLdouble -> GLdouble -> unit

        val c_glTranslatef : GLreal * GLreal * GLreal -> unit
        val glTranslatef : GLreal -> GLreal -> GLreal -> unit

        val c_glPolygonMode : GLenum * GLenum -> unit
        val glPolygonMode : GLenum -> GLenum -> unit

        val c_glPopMatrix : unit -> unit
        val glPopMatrix : unit -> unit

        val c_glPopAttrib : unit -> unit
        val glPopAttrib : unit -> unit

        val c_glPushAttrib : GLenum -> unit
        val glPushAttrib : GLenum -> unit

        val c_glRotatef: GLreal * GLreal * GLreal * GLreal -> unit
        val glRotatef: GLreal -> GLreal -> GLreal -> GLreal -> unit

        val c_glRotated: GLdouble * GLdouble * GLdouble * GLdouble -> unit
        val glRotated: GLdouble -> GLdouble -> GLdouble -> GLdouble -> unit

        val c_glShadeModel : GLenum -> unit
        val glShadeModel : GLenum -> unit

        val c_glVertex2d : GLdouble * GLdouble -> unit
        val glVertex2d : GLdouble -> GLdouble -> unit

        val c_glVertex3d : GLdouble * GLdouble * GLdouble -> unit
        val glVertex3d : GLdouble -> GLdouble -> GLdouble -> unit

        val c_glVertex2f : GLreal * GLreal -> unit
        val glVertex2f : GLreal -> GLreal -> unit

        val c_glVertex3f : GLreal * GLreal * GLreal -> unit
        val glVertex3f : GLreal -> GLreal -> GLreal -> unit

        val c_glViewport : int * int * int * int -> unit
        val glViewport : int -> int -> int -> int -> unit
    end





structure GL :> GL =
    struct






        type GLreal = Real32.real
        type GLdouble = real


        type GLenum = Word.word
        (* Specify attributes of (part) of a primitive *)
        (* needs to be extensible to different attributes and different formats,
         eg. ints and reals *)
        datatype realspec = realRGB of GLreal * GLreal * GLreal
        type realvertex = GLreal * GLreal * GLreal
        type realrgbacolour = GLreal list

        datatype intspec = intRGB of Word.word * Word.word * Word.word
        type intvertex = Word.word * Word.word * Word.word
        type intrgbacolour = Word.word * Word.word * Word.word * Word.word

        (* types of primitives *)
        type primitive = Word.word

        (* describes a collection of primitives *)
        type object = primitive * (realspec * realvertex list) list;

        (* AccumOp *)
        val GL_ACCUM = 0wx0100
        val GL_LOAD = 0wx0101
        val GL_RETURN = 0wx0102
        val GL_MULT = 0wx0103
        val GL_ADD = 0wx0104

        (* AlphaFunction *)
        val GL_NEVER = 0wx0200
        val GL_LESS = 0wx0201
        val GL_EQUAL = 0wx0202
        val GL_LEQUAL = 0wx0203
        val GL_GREATER = 0wx0204
        val GL_NOTEQUAL = 0wx0205
        val GL_GEQUAL = 0wx0206
        val GL_ALWAYS = 0wx0207

        (* AttribMask *)
        val GL_CURRENT_BIT = 0wx00000001
        val GL_POINT_BIT = 0wx00000002
        val GL_LINE_BIT = 0wx00000004
        val GL_POLYGON_BIT = 0wx00000008
        val GL_POLYGON_STIPPLE_BIT = 0wx00000010
        val GL_PIXEL_MODE_BIT = 0wx00000020
        val GL_LIGHTING_BIT = 0wx00000040
        val GL_FOG_BIT = 0wx00000080
        val GL_DEPTH_BUFFER_BIT = 0wx00000100
        val GL_ACCUM_BUFFER_BIT = 0wx00000200
        val GL_STENCIL_BUFFER_BIT = 0wx00000400
        val GL_VIEWPORT_BIT = 0wx00000800
        val GL_TRANSFORM_BIT = 0wx00001000
        val GL_ENABLE_BIT = 0wx00002000
        val GL_COLOR_BUFFER_BIT = 0wx00004000
        val GL_HINT_BIT = 0wx00008000
        val GL_EVAL_BIT = 0wx00010000
        val GL_LIST_BIT = 0wx00020000
        val GL_TEXTURE_BIT = 0wx00040000
        val GL_SCISSOR_BIT = 0wx00080000
        val GL_ALL_ATTRIB_BITS = 0wx000fffff

        (* BeginMode *)
        val GL_POINTS = 0wx0000
        val GL_LINES = 0wx0001
        val GL_LINE_LOOP = 0wx0002
        val GL_LINE_STRIP = 0wx0003
        val GL_TRIANGLES = 0wx0004
        val GL_TRIANGLE_STRIP = 0wx0005
        val GL_TRIANGLE_FAN = 0wx0006
        val GL_QUADS = 0wx0007
        val GL_QUAD_STRIP = 0wx0008
        val GL_POLYGON = 0wx0009

        (* BlendingFactorDest *)
        val GL_ZERO = 0w0
        val GL_ONE = 0w1
        val GL_SRC_COLOR = 0wx0300
        val GL_ONE_MINUS_SRC_COLOR = 0wx0301
        val GL_SRC_ALPHA = 0wx0302
        val GL_ONE_MINUS_SRC_ALPHA = 0wx0303
        val GL_DST_ALPHA = 0wx0304
        val GL_ONE_MINUS_DST_ALPHA = 0wx0305

        (* BlendingFactorSrc *)
        val GL_DST_COLOR = 0wx0306
        val GL_ONE_MINUS_DST_COLOR = 0wx0307
        val GL_SRC_ALPHA_SATURATE = 0wx0308

        (* Boolean *)
        val GL_TRUE = 0w1
        val GL_FALSE = 0w0

        (* ClipPlaneName *)
        val GL_CLIP_PLANE0 = 0wx3000
        val GL_CLIP_PLANE1 = 0wx3001
        val GL_CLIP_PLANE2 = 0wx3002
        val GL_CLIP_PLANE3 = 0wx3003
        val GL_CLIP_PLANE4 = 0wx3004
        val GL_CLIP_PLANE5 = 0wx3005

        (* DataType *)
        val GL_BYTE = 0wx1400
        val GL_UNSIGNED_BYTE = 0wx1401
        val GL_SHORT = 0wx1402
        val GL_UNSIGNED_SHORT = 0wx1403
        val GL_INT = 0wx1404
        val GL_UNSIGNED_INT = 0wx1405
        val GL_FLOAT = 0wx1406
        val GL_2_BYTES = 0wx1407
        val GL_3_BYTES = 0wx1408
        val GL_4_BYTES = 0wx1409
        val GL_DOUBLE = 0wx140A

        (* DrawBufferMode *)
        val GL_NONE = 0w0
        val GL_FRONT_LEFT = 0wx0400
        val GL_FRONT_RIGHT = 0wx0401
        val GL_BACK_LEFT = 0wx0402
        val GL_BACK_RIGHT = 0wx0403
        val GL_FRONT = 0wx0404
        val GL_BACK = 0wx0405
        val GL_LEFT = 0wx0406
        val GL_RIGHT = 0wx0407
        val GL_FRONT_AND_BACK = 0wx0408
        val GL_AUX0 = 0wx0409
        val GL_AUX1 = 0wx040A
        val GL_AUX2 = 0wx040B
        val GL_AUX3 = 0wx040C

        (* Enable *)
        (* ErrorCode *)
        val GL_NO_ERROR = 0w0
        val GL_INVALID_ENUM = 0wx0500
        val GL_INVALID_VALUE = 0wx0501
        val GL_INVALID_OPERATION = 0wx0502
        val GL_STACK_OVERFLOW = 0wx0503
        val GL_STACK_UNDERFLOW = 0wx0504
        val GL_OUT_OF_MEMORY = 0wx0505

        (* FeedBackMode *)
        val GL_2D = 0wx0600
        val GL_3D = 0wx0601
        val GL_3D_COLOR = 0wx0602
        val GL_3D_COLOR_TEXTURE = 0wx0603
        val GL_4D_COLOR_TEXTURE = 0wx0604

        (* FeedBackToken *)
        val GL_PASS_THROUGH_TOKEN = 0wx0700
        val GL_POINT_TOKEN = 0wx0701
        val GL_LINE_TOKEN = 0wx0702
        val GL_POLYGON_TOKEN = 0wx0703
        val GL_BITMAP_TOKEN = 0wx0704
        val GL_DRAW_PIXEL_TOKEN = 0wx0705
        val GL_COPY_PIXEL_TOKEN = 0wx0706
        val GL_LINE_RESET_TOKEN = 0wx0707

        (* FogMode *)
        val GL_EXP = 0wx0800
        val GL_EXP2 = 0wx0801

        (* FrontFaceDirection *)
        val GL_CW = 0wx0900
        val GL_CCW = 0wx0901

        (* GetMapTarget *)
        val GL_COEFF = 0wx0A00
        val GL_ORDER = 0wx0A01
        val GL_DOMAIN = 0wx0A02

        (* GetTarget *)
        val GL_CURRENT_COLOR = 0wx0B00
        val GL_CURRENT_INDEX = 0wx0B01
        val GL_CURRENT_NORMAL = 0wx0B02
        val GL_CURRENT_TEXTURE_COORDS = 0wx0B03
        val GL_CURRENT_RASTER_COLOR = 0wx0B04
        val GL_CURRENT_RASTER_INDEX = 0wx0B05
        val GL_CURRENT_RASTER_TEXTURE_COORDS = 0wx0B06
        val GL_CURRENT_RASTER_POSITION = 0wx0B07
        val GL_CURRENT_RASTER_POSITION_VALID = 0wx0B08
        val GL_CURRENT_RASTER_DISTANCE = 0wx0B09
        val GL_POINT_SMOOTH = 0wx0B10
        val GL_POINT_SIZE = 0wx0B11
        val GL_POINT_SIZE_RANGE = 0wx0B12
        val GL_POINT_SIZE_GRANULARITY = 0wx0B13
        val GL_LINE_SMOOTH = 0wx0B20
        val GL_LINE_WIDTH = 0wx0B21
        val GL_LINE_WIDTH_RANGE = 0wx0B22
        val GL_LINE_WIDTH_GRANULARITY = 0wx0B23
        val GL_LINE_STIPPLE = 0wx0B24
        val GL_LINE_STIPPLE_PATTERN = 0wx0B25
        val GL_LINE_STIPPLE_REPEAT = 0wx0B26
        val GL_LIST_MODE = 0wx0B30
        val GL_MAX_LIST_NESTING = 0wx0B31
        val GL_LIST_BASE = 0wx0B32
        val GL_LIST_INDEX = 0wx0B33
        val GL_POLYGON_MODE = 0wx0B40
        val GL_POLYGON_SMOOTH = 0wx0B41
        val GL_POLYGON_STIPPLE = 0wx0B42
        val GL_EDGE_FLAG = 0wx0B43
        val GL_CULL_FACE = 0wx0B44
        val GL_CULL_FACE_MODE = 0wx0B45
        val GL_FRONT_FACE = 0wx0B46
        val GL_LIGHTING = 0wx0B50
        val GL_LIGHT_MODEL_LOCAL_VIEWER = 0wx0B51
        val GL_LIGHT_MODEL_TWO_SIDE = 0wx0B52
        val GL_LIGHT_MODEL_AMBIENT = 0wx0B53
        val GL_SHADE_MODEL = 0wx0B54
        val GL_COLOR_MATERIAL_FACE = 0wx0B55
        val GL_COLOR_MATERIAL_PARAMETER = 0wx0B56
        val GL_COLOR_MATERIAL = 0wx0B57
        val GL_FOG = 0wx0B60
        val GL_FOG_INDEX = 0wx0B61
        val GL_FOG_DENSITY = 0wx0B62
        val GL_FOG_START = 0wx0B63
        val GL_FOG_END = 0wx0B64
        val GL_FOG_MODE = 0wx0B65
        val GL_FOG_COLOR = 0wx0B66
        val GL_DEPTH_RANGE = 0wx0B70
        val GL_DEPTH_TEST = 0wx0B71
        val GL_DEPTH_WRITEMASK = 0wx0B72
        val GL_DEPTH_CLEAR_VALUE = 0wx0B73
        val GL_DEPTH_FUNC = 0wx0B74
        val GL_ACCUM_CLEAR_VALUE = 0wx0B80
        val GL_STENCIL_TEST = 0wx0B90
        val GL_STENCIL_CLEAR_VALUE = 0wx0B91
        val GL_STENCIL_FUNC = 0wx0B92
        val GL_STENCIL_VALUE_MASK = 0wx0B93
        val GL_STENCIL_FAIL = 0wx0B94
        val GL_STENCIL_PASS_DEPTH_FAIL = 0wx0B95
        val GL_STENCIL_PASS_DEPTH_PASS = 0wx0B96
        val GL_STENCIL_REF = 0wx0B97
        val GL_STENCIL_WRITEMASK = 0wx0B98
        val GL_MATRIX_MODE = 0wx0BA0
        val GL_NORMALIZE = 0wx0BA1
        val GL_VIEWPORT = 0wx0BA2
        val GL_MODELVIEW_STACK_DEPTH = 0wx0BA3
        val GL_PROJECTION_STACK_DEPTH = 0wx0BA4
        val GL_TEXTURE_STACK_DEPTH = 0wx0BA5
        val GL_MODELVIEW_MATRIX = 0wx0BA6
        val GL_PROJECTION_MATRIX = 0wx0BA7
        val GL_TEXTURE_MATRIX = 0wx0BA8
        val GL_ATTRIB_STACK_DEPTH = 0wx0BB0
        val GL_CLIENT_ATTRIB_STACK_DEPTH = 0wx0BB1
        val GL_ALPHA_TEST = 0wx0BC0
        val GL_ALPHA_TEST_FUNC = 0wx0BC1
        val GL_ALPHA_TEST_REF = 0wx0BC2
        val GL_DITHER = 0wx0BD0
        val GL_BLEND_DST = 0wx0BE0
        val GL_BLEND_SRC = 0wx0BE1
        val GL_BLEND = 0wx0BE2
        val GL_LOGIC_OP_MODE = 0wx0BF0
        val GL_INDEX_LOGIC_OP = 0wx0BF1
        val GL_COLOR_LOGIC_OP = 0wx0BF2
        val GL_AUX_BUFFERS = 0wx0C00
        val GL_DRAW_BUFFER = 0wx0C01
        val GL_READ_BUFFER = 0wx0C02
        val GL_SCISSOR_BOX = 0wx0C10
        val GL_SCISSOR_TEST = 0wx0C11
        val GL_INDEX_CLEAR_VALUE = 0wx0C20
        val GL_INDEX_WRITEMASK = 0wx0C21
        val GL_COLOR_CLEAR_VALUE = 0wx0C22
        val GL_COLOR_WRITEMASK = 0wx0C23
        val GL_INDEX_MODE = 0wx0C30
        val GL_RGBA_MODE = 0wx0C31
        val GL_DOUBLEBUFFER = 0wx0C32
        val GL_STEREO = 0wx0C33
        val GL_RENDER_MODE = 0wx0C40
        val GL_PERSPECTIVE_CORRECTION_HINT = 0wx0C50
        val GL_POINT_SMOOTH_HINT = 0wx0C51
        val GL_LINE_SMOOTH_HINT = 0wx0C52
        val GL_POLYGON_SMOOTH_HINT = 0wx0C53
        val GL_FOG_HINT = 0wx0C54
        val GL_TEXTURE_GEN_S = 0wx0C60
        val GL_TEXTURE_GEN_T = 0wx0C61
        val GL_TEXTURE_GEN_R = 0wx0C62
        val GL_TEXTURE_GEN_Q = 0wx0C63
        val GL_PIXEL_MAP_I_TO_I = 0wx0C70
        val GL_PIXEL_MAP_S_TO_S = 0wx0C71
        val GL_PIXEL_MAP_I_TO_R = 0wx0C72
        val GL_PIXEL_MAP_I_TO_G = 0wx0C73
        val GL_PIXEL_MAP_I_TO_B = 0wx0C74
        val GL_PIXEL_MAP_I_TO_A = 0wx0C75
        val GL_PIXEL_MAP_R_TO_R = 0wx0C76
        val GL_PIXEL_MAP_G_TO_G = 0wx0C77
        val GL_PIXEL_MAP_B_TO_B = 0wx0C78
        val GL_PIXEL_MAP_A_TO_A = 0wx0C79
        val GL_PIXEL_MAP_I_TO_I_SIZE = 0wx0CB0
        val GL_PIXEL_MAP_S_TO_S_SIZE = 0wx0CB1
        val GL_PIXEL_MAP_I_TO_R_SIZE = 0wx0CB2
        val GL_PIXEL_MAP_I_TO_G_SIZE = 0wx0CB3
        val GL_PIXEL_MAP_I_TO_B_SIZE = 0wx0CB4
        val GL_PIXEL_MAP_I_TO_A_SIZE = 0wx0CB5
        val GL_PIXEL_MAP_R_TO_R_SIZE = 0wx0CB6
        val GL_PIXEL_MAP_G_TO_G_SIZE = 0wx0CB7
        val GL_PIXEL_MAP_B_TO_B_SIZE = 0wx0CB8
        val GL_PIXEL_MAP_A_TO_A_SIZE = 0wx0CB9
        val GL_UNPACK_SWAP_BYTES = 0wx0CF0
        val GL_UNPACK_LSB_FIRST = 0wx0CF1
        val GL_UNPACK_ROW_LENGTH = 0wx0CF2
        val GL_UNPACK_SKIP_ROWS = 0wx0CF3
        val GL_UNPACK_SKIP_PIXELS = 0wx0CF4
        val GL_UNPACK_ALIGNMENT = 0wx0CF5
        val GL_PACK_SWAP_BYTES = 0wx0D00
        val GL_PACK_LSB_FIRST = 0wx0D01
        val GL_PACK_ROW_LENGTH = 0wx0D02
        val GL_PACK_SKIP_ROWS = 0wx0D03
        val GL_PACK_SKIP_PIXELS = 0wx0D04
        val GL_PACK_ALIGNMENT = 0wx0D05
        val GL_MAP_COLOR = 0wx0D10
        val GL_MAP_STENCIL = 0wx0D11
        val GL_INDEX_SHIFT = 0wx0D12
        val GL_INDEX_OFFSET = 0wx0D13
        val GL_RED_SCALE = 0wx0D14
        val GL_RED_BIAS = 0wx0D15
        val GL_ZOOM_X = 0wx0D16
        val GL_ZOOM_Y = 0wx0D17
        val GL_GREEN_SCALE = 0wx0D18
        val GL_GREEN_BIAS = 0wx0D19
        val GL_BLUE_SCALE = 0wx0D1A
        val GL_BLUE_BIAS = 0wx0D1B
        val GL_ALPHA_SCALE = 0wx0D1C
        val GL_ALPHA_BIAS = 0wx0D1D
        val GL_DEPTH_SCALE = 0wx0D1E
        val GL_DEPTH_BIAS = 0wx0D1F
        val GL_MAX_EVAL_ORDER = 0wx0D30
        val GL_MAX_LIGHTS = 0wx0D31
        val GL_MAX_CLIP_PLANES = 0wx0D32
        val GL_MAX_TEXTURE_SIZE = 0wx0D33
        val GL_MAX_PIXEL_MAP_TABLE = 0wx0D34
        val GL_MAX_ATTRIB_STACK_DEPTH = 0wx0D35
        val GL_MAX_MODELVIEW_STACK_DEPTH = 0wx0D36
        val GL_MAX_NAME_STACK_DEPTH = 0wx0D37
        val GL_MAX_PROJECTION_STACK_DEPTH = 0wx0D38
        val GL_MAX_TEXTURE_STACK_DEPTH = 0wx0D39
        val GL_MAX_VIEWPORT_DIMS = 0wx0D3A
        val GL_MAX_CLIENT_ATTRIB_STACK_DEPTH = 0wx0D3B
        val GL_SUBPIXEL_BITS = 0wx0D50
        val GL_INDEX_BITS = 0wx0D51
        val GL_RED_BITS = 0wx0D52
        val GL_GREEN_BITS = 0wx0D53
        val GL_BLUE_BITS = 0wx0D54
        val GL_ALPHA_BITS = 0wx0D55
        val GL_DEPTH_BITS = 0wx0D56
        val GL_STENCIL_BITS = 0wx0D57
        val GL_ACCUM_RED_BITS = 0wx0D58
        val GL_ACCUM_GREEN_BITS = 0wx0D59
        val GL_ACCUM_BLUE_BITS = 0wx0D5A
        val GL_ACCUM_ALPHA_BITS = 0wx0D5B
        val GL_NAME_STACK_DEPTH = 0wx0D70
        val GL_AUTO_NORMAL = 0wx0D80
        val GL_MAP1_COLOR_4 = 0wx0D90
        val GL_MAP1_INDEX = 0wx0D91
        val GL_MAP1_NORMAL = 0wx0D92
        val GL_MAP1_TEXTURE_COORD_1 = 0wx0D93
        val GL_MAP1_TEXTURE_COORD_2 = 0wx0D94
        val GL_MAP1_TEXTURE_COORD_3 = 0wx0D95
        val GL_MAP1_TEXTURE_COORD_4 = 0wx0D96
        val GL_MAP1_VERTEX_3 = 0wx0D97
        val GL_MAP1_VERTEX_4 = 0wx0D98
        val GL_MAP2_COLOR_4 = 0wx0DB0
        val GL_MAP2_INDEX = 0wx0DB1
        val GL_MAP2_NORMAL = 0wx0DB2
        val GL_MAP2_TEXTURE_COORD_1 = 0wx0DB3
        val GL_MAP2_TEXTURE_COORD_2 = 0wx0DB4
        val GL_MAP2_TEXTURE_COORD_3 = 0wx0DB5
        val GL_MAP2_TEXTURE_COORD_4 = 0wx0DB6
        val GL_MAP2_VERTEX_3 = 0wx0DB7
        val GL_MAP2_VERTEX_4 = 0wx0DB8
        val GL_MAP1_GRID_DOMAIN = 0wx0DD0
        val GL_MAP1_GRID_SEGMENTS = 0wx0DD1
        val GL_MAP2_GRID_DOMAIN = 0wx0DD2
        val GL_MAP2_GRID_SEGMENTS = 0wx0DD3
        val GL_TEXTURE_1D = 0wx0DE0
        val GL_TEXTURE_2D = 0wx0DE1
        val GL_FEEDBACK_BUFFER_POINTER = 0wx0DF0
        val GL_FEEDBACK_BUFFER_SIZE = 0wx0DF1
        val GL_FEEDBACK_BUFFER_TYPE = 0wx0DF2
        val GL_SELECTION_BUFFER_POINTER = 0wx0DF3
        val GL_SELECTION_BUFFER_SIZE = 0wx0DF4

        (* GetTextureParameter *)
        val GL_TEXTURE_WIDTH = 0wx1000
        val GL_TEXTURE_HEIGHT = 0wx1001
        val GL_TEXTURE_INTERNAL_FORMAT = 0wx1003
        val GL_TEXTURE_BORDER_COLOR = 0wx1004
        val GL_TEXTURE_BORDER = 0wx1005

        (* HintMode *)
        val GL_DONT_CARE = 0wx1100
        val GL_FASTEST = 0wx1101
        val GL_NICEST = 0wx1102

        (* LightName *)
        val GL_LIGHT0 = 0wx4000
        val GL_LIGHT1 = 0wx4001
        val GL_LIGHT2 = 0wx4002
        val GL_LIGHT3 = 0wx4003
        val GL_LIGHT4 = 0wx4004
        val GL_LIGHT5 = 0wx4005
        val GL_LIGHT6 = 0wx4006
        val GL_LIGHT7 = 0wx4007

        (* LightParameter *)
        val GL_AMBIENT = 0wx1200
        val GL_DIFFUSE = 0wx1201
        val GL_SPECULAR = 0wx1202
        val GL_POSITION = 0wx1203
        val GL_SPOT_DIRECTION = 0wx1204
        val GL_SPOT_EXPONENT = 0wx1205
        val GL_SPOT_CUTOFF = 0wx1206
        val GL_CONSTANT_ATTENUATION = 0wx1207
        val GL_LINEAR_ATTENUATION = 0wx1208
        val GL_QUADRATIC_ATTENUATION = 0wx1209

        (* ListMode *)
        val GL_COMPILE = 0wx1300
        val GL_COMPILE_AND_EXECUTE = 0wx1301

        (* LogicOp *)
        val GL_CLEAR = 0wx1500
        val GL_AND = 0wx1501
        val GL_AND_REVERSE = 0wx1502
        val GL_COPY = 0wx1503
        val GL_AND_INVERTED = 0wx1504
        val GL_NOOP = 0wx1505
        val GL_XOR = 0wx1506
        val GL_OR = 0wx1507
        val GL_NOR = 0wx1508
        val GL_EQUIV = 0wx1509
        val GL_INVERT = 0wx150A
        val GL_OR_REVERSE = 0wx150B
        val GL_COPY_INVERTED = 0wx150C
        val GL_OR_INVERTED = 0wx150D
        val GL_NAND = 0wx150E
        val GL_SET = 0wx150F

        (* MaterialParameter *)
        val GL_EMISSION = 0wx1600
        val GL_SHININESS = 0wx1601
        val GL_AMBIENT_AND_DIFFUSE = 0wx1602
        val GL_COLOR_INDEXES = 0wx1603

        (* MatrixMode *)
        val GL_MODELVIEW = 0wx1700
        val GL_PROJECTION = 0wx1701
        val GL_TEXTURE = 0wx1702

        (* PixelCopyType *)
        val GL_COLOR = 0wx1800
        val GL_DEPTH = 0wx1801
        val GL_STENCIL = 0wx1802

        (* PixelFormat *)
        val GL_COLOR_INDEX = 0wx1900
        val GL_STENCIL_INDEX = 0wx1901
        val GL_DEPTH_COMPONENT = 0wx1902
        val GL_RED = 0wx1903
        val GL_GREEN = 0wx1904
        val GL_BLUE = 0wx1905
        val GL_ALPHA = 0wx1906
        val GL_RGB = 0wx1907
        val GL_RGBA = 0wx1908
        val GL_LUMINANCE = 0wx1909
        val GL_LUMINANCE_ALPHA = 0wx190A

        (* PixelType *)
        val GL_BITMAP = 0wx1A00

        (* PolygonMode *)
        val GL_POINT = 0wx1B00
        val GL_LINE = 0wx1B01
        val GL_FILL = 0wx1B02

        (* RenderingMode *)
        val GL_RENDER = 0wx1C00
        val GL_FEEDBACK = 0wx1C01
        val GL_SELECT = 0wx1C02

        (* ShadingModel *)
        val GL_FLAT = 0wx1D00
        val GL_SMOOTH = 0wx1D01

        (* StencilOp *)
        val GL_KEEP = 0wx1E00
        val GL_REPLACE = 0wx1E01
        val GL_INCR = 0wx1E02
        val GL_DECR = 0wx1E03

        (* StringName *)
        val GL_VENDOR = 0wx1F00
        val GL_RENDERER = 0wx1F01
        val GL_VERSION = 0wx1F02
        val GL_EXTENSIONS = 0wx1F03

        (* TextureCoordName *)
        val GL_S = 0wx2000
        val GL_T = 0wx2001
        val GL_R = 0wx2002
        val GL_Q = 0wx2003

        (* TextureEnvMode *)
        val GL_MODULATE = 0wx2100
        val GL_DECAL = 0wx2101

        (* TextureEnvParameter *)
        val GL_TEXTURE_ENV_MODE = 0wx2200
        val GL_TEXTURE_ENV_COLOR = 0wx2201

        (* TextureEnvTarget *)
        val GL_TEXTURE_ENV = 0wx2300

        (* TextureGenMode *)
        val GL_EYE_LINEAR = 0wx2400
        val GL_OBJECT_LINEAR = 0wx2401
        val GL_SPHERE_MAP = 0wx2402

        (* TextureGenParameter *)
        val GL_TEXTURE_GEN_MODE = 0wx2500
        val GL_OBJECT_PLANE = 0wx2501
        val GL_EYE_PLANE = 0wx2502

        (* TextureMagFilter *)
        val GL_NEAREST = 0wx2600
        val GL_LINEAR = 0wx2601

        (* TextureMinFilter *)
        val GL_NEAREST_MIPMAP_NEAREST = 0wx2700
        val GL_LINEAR_MIPMAP_NEAREST = 0wx2701
        val GL_NEAREST_MIPMAP_LINEAR = 0wx2702
        val GL_LINEAR_MIPMAP_LINEAR = 0wx2703

        (* TextureParameterName *)
        val GL_TEXTURE_MAG_FILTER = 0wx2800
        val GL_TEXTURE_MIN_FILTER = 0wx2801
        val GL_TEXTURE_WRAP_S = 0wx2802
        val GL_TEXTURE_WRAP_T = 0wx2803

        (* TextureWrapMode *)
        val GL_CLAMP = 0wx2900
        val GL_REPEAT = 0wx2901

        (* ClientAttribMask *)
        val GL_CLIENT_PIXEL_STORE_BIT = 0wx00000001
        val GL_CLIENT_VERTEX_ARRAY_BIT = 0wx00000002
        (* val GL_CLIENT_ALL_ATTRIB_BITS = 0wxffffffff *)
        val GL_CLIENT_ALL_ATTRIB_BITS =
            Word8Vector.fromList [0wxFF, 0wxFF, 0wxFF, 0wxFF];
        (* polygon_offset *)
        val GL_POLYGON_OFFSET_FACTOR = 0wx8038
        val GL_POLYGON_OFFSET_UNITS = 0wx2A00
        val GL_POLYGON_OFFSET_POINT = 0wx2A01
        val GL_POLYGON_OFFSET_LINE = 0wx2A02
        val GL_POLYGON_OFFSET_FILL = 0wx8037

        (* texture *)
        val GL_ALPHA4 = 0wx803B
        val GL_ALPHA8 = 0wx803C
        val GL_ALPHA12 = 0wx803D
        val GL_ALPHA16 = 0wx803E
        val GL_LUMINANCE4 = 0wx803F
        val GL_LUMINANCE8 = 0wx8040
        val GL_LUMINANCE12 = 0wx8041
        val GL_LUMINANCE16 = 0wx8042
        val GL_LUMINANCE4_ALPHA4 = 0wx8043
        val GL_LUMINANCE6_ALPHA2 = 0wx8044
        val GL_LUMINANCE8_ALPHA8 = 0wx8045
        val GL_LUMINANCE12_ALPHA4 = 0wx8046
        val GL_LUMINANCE12_ALPHA12 = 0wx8047
        val GL_LUMINANCE16_ALPHA16 = 0wx8048
        val GL_INTENSITY = 0wx8049
        val GL_INTENSITY4 = 0wx804A
        val GL_INTENSITY8 = 0wx804B
        val GL_INTENSITY12 = 0wx804C
        val GL_INTENSITY16 = 0wx804D
        val GL_R3_G3_B2 = 0wx2A10
        val GL_RGB4 = 0wx804F
        val GL_RGB5 = 0wx8050
        val GL_RGB8 = 0wx8051
        val GL_RGB10 = 0wx8052
        val GL_RGB12 = 0wx8053
        val GL_RGB16 = 0wx8054
        val GL_RGBA2 = 0wx8055
        val GL_RGBA4 = 0wx8056
        val GL_RGB5_A1 = 0wx8057
        val GL_RGBA8 = 0wx8058
        val GL_RGB10_A2 = 0wx8059
        val GL_RGBA12 = 0wx805A
        val GL_RGBA16 = 0wx805B
        val GL_TEXTURE_RED_SIZE = 0wx805C
        val GL_TEXTURE_GREEN_SIZE = 0wx805D
        val GL_TEXTURE_BLUE_SIZE = 0wx805E
        val GL_TEXTURE_ALPHA_SIZE = 0wx805F
        val GL_TEXTURE_LUMINANCE_SIZE = 0wx8060
        val GL_TEXTURE_INTENSITY_SIZE = 0wx8061
        val GL_PROXY_TEXTURE_1D = 0wx8063
        val GL_PROXY_TEXTURE_2D = 0wx8064

        (* texture_object *)
        val GL_TEXTURE_PRIORITY = 0wx8066
        val GL_TEXTURE_RESIDENT = 0wx8067
        val GL_TEXTURE_BINDING_1D = 0wx8068
        val GL_TEXTURE_BINDING_2D = 0wx8069

        (* vertex_array *)
        val GL_VERTEX_ARRAY = 0wx8074
        val GL_NORMAL_ARRAY = 0wx8075
        val GL_COLOR_ARRAY = 0wx8076
        val GL_INDEX_ARRAY = 0wx8077
        val GL_TEXTURE_COORD_ARRAY = 0wx8078
        val GL_EDGE_FLAG_ARRAY = 0wx8079
        val GL_VERTEX_ARRAY_SIZE = 0wx807A
        val GL_VERTEX_ARRAY_TYPE = 0wx807B
        val GL_VERTEX_ARRAY_STRIDE = 0wx807C
        val GL_NORMAL_ARRAY_TYPE = 0wx807E
        val GL_NORMAL_ARRAY_STRIDE = 0wx807F
        val GL_COLOR_ARRAY_SIZE = 0wx8081
        val GL_COLOR_ARRAY_TYPE = 0wx8082
        val GL_COLOR_ARRAY_STRIDE = 0wx8083
        val GL_INDEX_ARRAY_TYPE = 0wx8085
        val GL_INDEX_ARRAY_STRIDE = 0wx8086
        val GL_TEXTURE_COORD_ARRAY_SIZE = 0wx8088
        val GL_TEXTURE_COORD_ARRAY_TYPE = 0wx8089
        val GL_TEXTURE_COORD_ARRAY_STRIDE = 0wx808A
        val GL_EDGE_FLAG_ARRAY_STRIDE = 0wx808C
        val GL_VERTEX_ARRAY_POINTER = 0wx808E
        val GL_NORMAL_ARRAY_POINTER = 0wx808F
        val GL_COLOR_ARRAY_POINTER = 0wx8090
        val GL_INDEX_ARRAY_POINTER = 0wx8091
        val GL_TEXTURE_COORD_ARRAY_POINTER = 0wx8092
        val GL_EDGE_FLAG_ARRAY_POINTER = 0wx8093
        val GL_V2F = 0wx2A20
        val GL_V3F = 0wx2A21
        val GL_C4UB_V2F = 0wx2A22
        val GL_C4UB_V3F = 0wx2A23
        val GL_C3F_V3F = 0wx2A24
        val GL_N3F_V3F = 0wx2A25
        val GL_C4F_N3F_V3F = 0wx2A26
        val GL_T2F_V3F = 0wx2A27
        val GL_T4F_V4F = 0wx2A28
        val GL_T2F_C4UB_V3F = 0wx2A29
        val GL_T2F_C3F_V3F = 0wx2A2A
        val GL_T2F_N3F_V3F = 0wx2A2B
        val GL_T2F_C4F_N3F_V3F = 0wx2A2C
        val GL_T4F_C4F_N3F_V4F = 0wx2A2D

        (* Extensions *)
        val GL_EXT_vertex_array = 0w1
        val GL_WIN_swap_hint = 0w1
        val GL_EXT_bgra = 0w1
        val GL_EXT_paletted_texture = 0w1

        (* EXT_vertex_array *)
        val GL_VERTEX_ARRAY_EXT = 0wx8074
        val GL_NORMAL_ARRAY_EXT = 0wx8075
        val GL_COLOR_ARRAY_EXT = 0wx8076
        val GL_INDEX_ARRAY_EXT = 0wx8077
        val GL_TEXTURE_COORD_ARRAY_EXT = 0wx8078
        val GL_EDGE_FLAG_ARRAY_EXT = 0wx8079
        val GL_VERTEX_ARRAY_SIZE_EXT = 0wx807A
        val GL_VERTEX_ARRAY_TYPE_EXT = 0wx807B
        val GL_VERTEX_ARRAY_STRIDE_EXT = 0wx807C
        val GL_VERTEX_ARRAY_COUNT_EXT = 0wx807D
        val GL_NORMAL_ARRAY_TYPE_EXT = 0wx807E
        val GL_NORMAL_ARRAY_STRIDE_EXT = 0wx807F
        val GL_NORMAL_ARRAY_COUNT_EXT = 0wx8080
        val GL_COLOR_ARRAY_SIZE_EXT = 0wx8081
        val GL_COLOR_ARRAY_TYPE_EXT = 0wx8082
        val GL_COLOR_ARRAY_STRIDE_EXT = 0wx8083
        val GL_COLOR_ARRAY_COUNT_EXT = 0wx8084
        val GL_INDEX_ARRAY_TYPE_EXT = 0wx8085
        val GL_INDEX_ARRAY_STRIDE_EXT = 0wx8086
        val GL_INDEX_ARRAY_COUNT_EXT = 0wx8087
        val GL_TEXTURE_COORD_ARRAY_SIZE_EXT = 0wx8088
        val GL_TEXTURE_COORD_ARRAY_TYPE_EXT = 0wx8089
        val GL_TEXTURE_COORD_ARRAY_STRIDE_EXT =0wx808A
        val GL_TEXTURE_COORD_ARRAY_COUNT_EXT = 0wx808B
        val GL_EDGE_FLAG_ARRAY_STRIDE_EXT = 0wx808C
        val GL_EDGE_FLAG_ARRAY_COUNT_EXT = 0wx808D
        val GL_VERTEX_ARRAY_POINTER_EXT = 0wx808E
        val GL_NORMAL_ARRAY_POINTER_EXT = 0wx808F
        val GL_COLOR_ARRAY_POINTER_EXT = 0wx8090
        val GL_INDEX_ARRAY_POINTER_EXT = 0wx8091
        val GL_TEXTURE_COORD_ARRAY_POINTER_EXT =0wx8092
        val GL_EDGE_FLAG_ARRAY_POINTER_EXT = 0wx8093
        val GL_DOUBLE_EXT = GL_DOUBLE

        (* EXT_bgra *)
        val GL_BGR_EXT = 0wx80E0
        val GL_BGRA_EXT = 0wx80E1

        (* EXT_paletted_texture *)
        (* These must match the GL_COLOR_TABLE_*_SGI enumerants *)
        val GL_COLOR_TABLE_FORMAT_EXT = 0wx80D8
        val GL_COLOR_TABLE_WIDTH_EXT = 0wx80D9
        val GL_COLOR_TABLE_RED_SIZE_EXT = 0wx80DA
        val GL_COLOR_TABLE_GREEN_SIZE_EXT = 0wx80DB
        val GL_COLOR_TABLE_BLUE_SIZE_EXT = 0wx80DC
        val GL_COLOR_TABLE_ALPHA_SIZE_EXT = 0wx80DD
        val GL_COLOR_TABLE_LUMINANCE_SIZE_EXT =0wx80DE
        val GL_COLOR_TABLE_INTENSITY_SIZE_EXT =0wx80DF

        val GL_COLOR_INDEX1_EXT = 0wx80E2
        val GL_COLOR_INDEX2_EXT = 0wx80E3
        val GL_COLOR_INDEX4_EXT = 0wx80E4
        val GL_COLOR_INDEX8_EXT = 0wx80E5
        val GL_COLOR_INDEX12_EXT = 0wx80E6
        val GL_COLOR_INDEX16_EXT = 0wx80E7

        (* For compatibility with OpenGL v1.0 *)

        val GL_LOGIC_OP = GL_INDEX_LOGIC_OP
        val GL_TEXTURE_COMPONENTS = GL_TEXTURE_INTERNAL_FORMAT
        val c_glBegin = _import "glBegin" stdcall: GLenum -> unit;
        fun glBegin (a:GLenum)= c_glBegin (a): unit;

        val c_glEnd = _import "glEnd" stdcall: unit -> unit;
        fun glEnd ()= c_glEnd (): unit;

        val c_glBlendFunc = _import "glBlendFunc" stdcall: GLenum * GLenum -> unit;
        fun glBlendFunc (a:GLenum) (b:GLenum) = c_glBlendFunc (a,b) :unit

        val c_glCallList = _import "glCallList" stdcall: int -> unit;
        fun glCallList (a:int) = c_glCallList (a): unit;

        val c_glClearColor = _import "glClearColor" stdcall:
                               GLreal * GLreal * GLreal * GLreal -> unit;
        fun glClearColor (a:GLreal) (b:GLreal) (c:GLreal) (d:GLreal)
          = c_glClearColor (a,b,c,d) : unit

        val c_glClearDepth = _import "glClearDepth" stdcall: GLreal -> unit;
        fun glClearDepth (a:GLreal) = c_glClearDepth a : unit

        val c_glLineWidth = _import "glLineWidth" stdcall: GLreal -> unit;
        fun glLineWidth (a:GLreal) = c_glLineWidth a : unit

        val c_glColor3d = _import "glColor3d" stdcall: GLdouble * GLdouble * GLdouble -> unit;
        fun glColor3d (a:GLdouble) (b:GLdouble) (c:GLdouble)
          = c_glColor3d (a,b,c) : unit

        val c_glColor3f = _import "glColor3f" stdcall: GLreal * GLreal * GLreal -> unit;
        fun glColor3f (a:GLreal) (b:GLreal) (c:GLreal)
          = c_glColor3f (a,b,c) : unit

        val c_glColor3ub = _import "glColor3ub" stdcall: Word8.word * Word8.word * Word8.word -> unit;
        fun glColor3ub (a:Word8.word) (b:Word8.word) (c:Word8.word)
          = c_glColor3ub (a,b,c) : unit

        val c_glColor4d = _import "glColor4d" stdcall: GLdouble * GLdouble * GLdouble * GLdouble -> unit;
        fun glColor4d (a:GLdouble) (b:GLdouble) (c:GLdouble) (d:GLdouble)
          = c_glColor4d (a,b,c,d) : unit

        val c_glColor4f = _import "glColor4f" stdcall: GLreal * GLreal * GLreal * GLreal -> unit;
        fun glColor4f (a:GLreal) (b:GLreal) (c:GLreal) (d:GLreal)
          = c_glColor4f (a,b,c,d) : unit

        val c_glColor4ub = _import "glColor4ub" stdcall: Word8.word * Word8.word * Word8.word * Word8.word -> unit;
        fun glColor4ub (a:Word8.word) (b:Word8.word) (c:Word8.word) (d:Word8.word)
          = c_glColor4ub (a,b,c,d) : unit

        val c_glColorMaterial = _import "glColorMaterial" stdcall: GLenum * GLenum -> unit;
        fun glColorMaterial (a:GLenum) (b:GLenum) = c_glColorMaterial (a,b) : unit

        val c_glDisable = _import "glDisable" stdcall: GLenum -> unit;
        fun glDisable (a:GLenum)= c_glDisable (a): unit;

        val c_glEnable = _import "glEnable" stdcall: GLenum -> unit;
        fun glEnable (a:GLenum)= c_glEnable (a): unit;

        val c_glRasterPos2i = _import "glRasterPos2i" stdcall: int * int -> unit;
        fun glRasterPos2i (a:int) (b:int)
          = c_glRasterPos2i (a,b) : unit

        val c_glRasterPos2f = _import "glRasterPos2f" stdcall: GLreal * GLreal -> unit;
        fun glRasterPos2f (a:GLreal) (b:GLreal)
          = c_glRasterPos2f (a,b) : unit

        val c_glRasterPos2d = _import "glRasterPos2d" stdcall: GLdouble * GLdouble -> unit;
        fun glRasterPos2d (a:GLdouble) (b:GLdouble)
          = c_glRasterPos2d (a,b) : unit

        val c_glShadeModel = _import "glShadeModel" stdcall: GLenum -> unit;
        fun glShadeModel (a:GLenum)= c_glShadeModel (a): unit;

        val c_glClear = _import "glClear" stdcall: GLenum -> unit;
        fun glClear (a:GLenum)= c_glClear (a): unit;

        val c_glEndList = _import "glEndList" stdcall: unit -> unit;
        fun glEndList () = c_glEndList (): unit;

        val c_glFlush = _import "glFlush" stdcall: unit -> unit;
        fun glFlush () = c_glFlush (): unit;

        val c_glFrontFace = _import "glFrontFace" stdcall: GLenum -> unit;
        fun glFrontFace (a:GLenum)= c_glFrontFace (a): unit;

        val c_glLightfv = _import "glLightfv" stdcall: GLenum * GLenum * GLreal array -> unit;
        fun glLightfv (a:GLenum) (c:GLenum) (b:realrgbacolour) =
            let
                val rgba = Array.fromList b
            in
                c_glLightfv (a, c, rgba)
            end :unit

        val c_glLightModelfv = _import "glLightModelfv" stdcall: GLenum * GLreal array -> unit;
        fun glLightModelfv (a:GLenum) (b:realrgbacolour) =
            let
                val rgba = Array.fromList b
            in
                c_glLightModelfv (a, rgba)
            end :unit

        val c_glLoadIdentity = _import "glLoadIdentity" stdcall: unit -> unit;
        fun glLoadIdentity () = c_glLoadIdentity (): unit;

        val c_glMaterialfv = _import "glMaterialfv" stdcall: GLenum * GLenum * GLreal array -> unit;
        fun glMaterialfv (a:GLenum) (c:GLenum) (b:GLreal array) = c_glMaterialfv (a, c, b) :unit;

        val c_glMatrixMode = _import "glMatrixMode" stdcall: GLenum -> unit;
        fun glMatrixMode (a:GLenum)= c_glMatrixMode (a): unit;

        val c_glNewList = _import "glNewList" stdcall: int * GLenum -> unit;
        fun glNewList (b:int) (a:GLenum)= c_glNewList (b,a): unit;

        val c_glOrtho = _import "glOrtho" stdcall: GLdouble * GLdouble * GLdouble * GLdouble * GLdouble * GLdouble -> unit;
        fun glOrtho (a0 : GLdouble) (a1 : GLdouble) (a2 : GLdouble)
            (a3 : GLdouble) (a4 : GLdouble) (a5 : GLdouble) =
                c_glOrtho (a0, a1, a2, a3, a4, a5)

        val c_glPushMatrix = _import "glPushMatrix" stdcall: unit -> unit;
        fun glPushMatrix () = c_glPushMatrix (): unit;

        val c_glPopAttrib = _import "glPopAttrib" stdcall: unit -> unit;
        fun glPopAttrib () = c_glPopAttrib (): unit;

        val c_glPushAttrib = _import "glPushAttrib" stdcall: GLenum -> unit;
        fun glPushAttrib (a:GLenum)= c_glPushAttrib (a): unit;

        val c_glPolygonMode = _import "glPolygonMode" stdcall: GLenum * GLenum -> unit;
        fun glPolygonMode (a:GLenum) (b:GLenum) = c_glPolygonMode (a,b) :unit

        val c_glPopMatrix = _import "glPopMatrix" stdcall: unit -> unit;
        fun glPopMatrix () = c_glPopMatrix (): unit;

        val c_glTranslated = _import "glTranslated" stdcall: GLdouble * GLdouble * GLdouble -> unit;
        fun glTranslated (a:GLdouble) (b:GLdouble) (c:GLdouble)
          = c_glTranslated (a,b,c) : unit

        val c_glTranslatef = _import "glTranslatef" stdcall: GLreal * GLreal * GLreal -> unit;
        fun glTranslatef (a:GLreal) (b:GLreal) (c:GLreal)
          = c_glTranslatef (a,b,c) : unit

        val c_glViewport = _import "glViewport" stdcall: int * int * int * int -> unit;
        fun glViewport (a:int) (b:int) (c:int) (d:int) = c_glViewport (a,b,c,d) : unit

        val c_glRotatef = _import "glRotatef" stdcall: GLreal * GLreal * GLreal * GLreal -> unit;
        fun glRotatef (a:GLreal) (b:GLreal) (c:GLreal) (d:GLreal)
          = c_glRotatef (a,b,c,d) : unit

        val c_glRotated = _import "glRotated" stdcall: GLdouble * GLdouble * GLdouble * GLdouble -> unit;
        fun glRotated (a:GLdouble) (b:GLdouble) (c:GLdouble) (d:GLdouble)
          = c_glRotated (a,b,c,d) : unit

        val c_glVertex2f = _import "glVertex2f" stdcall: GLreal * GLreal -> unit;
        fun glVertex2f (a:GLreal) (b:GLreal)
          = c_glVertex2f (a,b) : unit

        val c_glVertex2d = _import "glVertex2d" stdcall: GLdouble * GLdouble -> unit;
        fun glVertex2d (a:GLdouble) (b:GLdouble)
          = c_glVertex2d (a,b) : unit

        val c_glVertex3d = _import "glVertex3d" stdcall: GLdouble * GLdouble * GLdouble -> unit;
        fun glVertex3d (a:GLdouble) (b:GLdouble) (c:GLdouble)
          = c_glVertex3d (a,b,c) : unit

        val c_glVertex3f = _import "glVertex3f" stdcall: GLreal * GLreal * GLreal -> unit;
        fun glVertex3f (a:GLreal) (b:GLreal) (c:GLreal)
          = c_glVertex3f (a,b,c) : unit
    end



open GL
signature GLUT =
    sig

        type glutfont = MLton.Pointer.t
        (* Display mode bit masks. *)
        val GLUT_RGB : GL.GLenum
        val GLUT_RGBA : GL.GLenum
        val GLUT_INDEX : GL.GLenum
        val GLUT_SINGLE : GL.GLenum
        val GLUT_DOUBLE : GL.GLenum
        val GLUT_ACCUM : GL.GLenum
        val GLUT_ALPHA : GL.GLenum
        val GLUT_DEPTH : GL.GLenum
        val GLUT_STENCIL : GL.GLenum
        (* #if (GLUT_API_VERSION >= 2) *)
        val GLUT_MULTISAMPLE : GL.GLenum
        val GLUT_STEREO : GL.GLenum
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 3) *)
        val GLUT_LUMINANCE : GL.GLenum
        (* #endif *)

        (* Mouse buttons. *)
        val GLUT_LEFT_BUTTON : GL.GLenum
        val GLUT_MIDDLE_BUTTON : GL.GLenum
        val GLUT_RIGHT_BUTTON : GL.GLenum

        (* Mouse button state. *)
        val GLUT_DOWN : GL.GLenum
        val GLUT_UP : GL.GLenum

        (* #if (GLUT_API_VERSION >= 2) *)
        (* function keys *)
        val GLUT_KEY_F1 : GL.GLenum
        val GLUT_KEY_F2 : GL.GLenum
        val GLUT_KEY_F3 : GL.GLenum
        val GLUT_KEY_F4 : GL.GLenum
        val GLUT_KEY_F5 : GL.GLenum
        val GLUT_KEY_F6 : GL.GLenum
        val GLUT_KEY_F7 : GL.GLenum
        val GLUT_KEY_F8 : GL.GLenum
        val GLUT_KEY_F9 : GL.GLenum
        val GLUT_KEY_F10 : GL.GLenum
        val GLUT_KEY_F11 : GL.GLenum
        val GLUT_KEY_F12 : GL.GLenum
        (* directional keys *)
        val GLUT_KEY_LEFT : GL.GLenum
        val GLUT_KEY_UP : GL.GLenum
        val GLUT_KEY_RIGHT : GL.GLenum
        val GLUT_KEY_DOWN : GL.GLenum
        val GLUT_KEY_PAGE_UP : GL.GLenum
        val GLUT_KEY_PAGE_DOWN : GL.GLenum
        val GLUT_KEY_HOME : GL.GLenum
        val GLUT_KEY_END : GL.GLenum
        val GLUT_KEY_INSERT : GL.GLenum
        (* #endif *)

        (* Entry/exit state. *)
        val GLUT_LEFT : GL.GLenum
        val GLUT_ENTERED : GL.GLenum

        (* Menu usage state. *)
        val GLUT_MENU_NOT_IN_USE : GL.GLenum
        val GLUT_MENU_IN_USE : GL.GLenum

        (* Visibility state. *)
        val GLUT_NOT_VISIBLE : GL.GLenum
        val GLUT_VISIBLE : GL.GLenum

        (* Window status state. *)
        val GLUT_HIDDEN : GL.GLenum
        val GLUT_FULLY_RETAINED : GL.GLenum
        val GLUT_PARTIALLY_RETAINED : GL.GLenum
        val GLUT_FULLY_COVERED : GL.GLenum

        (* Color index component selection values. *)
        val GLUT_RED : GL.GLenum
        val GLUT_GREEN : GL.GLenum
        val GLUT_BLUE : GL.GLenum

        (* Layers for use. *)
        val GLUT_NORMAL : GL.GLenum
        val GLUT_OVERLAY : GL.GLenum

        (* Stroke font constants (use these in GLUT program). *)
        val GLUT_STROKE_ROMAN : glutfont
        val GLUT_STROKE_MONO_ROMAN : glutfont

        (* Bitmap font constants (use these in GLUT program). *)
        val GLUT_BITMAP_9_BY_15 : glutfont
        val GLUT_BITMAP_8_BY_13 : glutfont
        val GLUT_BITMAP_TIMES_ROMAN_10 : glutfont
        val GLUT_BITMAP_TIMES_ROMAN_24 : glutfont
        (*#if (GLUT_API_VERSION >= 3)*)
        val GLUT_BITMAP_HELVETICA_10 : glutfont
        val GLUT_BITMAP_HELVETICA_12 : glutfont
        val GLUT_BITMAP_HELVETICA_18 : glutfont
        (*#endif *)

        (* glutGet parameters. *)
        val GLUT_WINDOW_X : GL.GLenum
        val GLUT_WINDOW_Y : GL.GLenum
        val GLUT_WINDOW_WIDTH : GL.GLenum
        val GLUT_WINDOW_HEIGHT : GL.GLenum
        val GLUT_WINDOW_BUFFER_SIZE : GL.GLenum
        val GLUT_WINDOW_STENCIL_SIZE : GL.GLenum
        val GLUT_WINDOW_DEPTH_SIZE : GL.GLenum
        val GLUT_WINDOW_RED_SIZE : GL.GLenum
        val GLUT_WINDOW_GREEN_SIZE : GL.GLenum
        val GLUT_WINDOW_BLUE_SIZE : GL.GLenum
        val GLUT_WINDOW_ALPHA_SIZE : GL.GLenum
        val GLUT_WINDOW_ACCUM_RED_SIZE : GL.GLenum
        val GLUT_WINDOW_ACCUM_GREEN_SIZE : GL.GLenum
        val GLUT_WINDOW_ACCUM_BLUE_SIZE : GL.GLenum
        val GLUT_WINDOW_ACCUM_ALPHA_SIZE : GL.GLenum
        val GLUT_WINDOW_DOUBLEBUFFER : GL.GLenum
        val GLUT_WINDOW_RGBA : GL.GLenum
        val GLUT_WINDOW_PARENT : GL.GLenum
        val GLUT_WINDOW_NUM_CHILDREN : GL.GLenum
        val GLUT_WINDOW_COLORMAP_SIZE : GL.GLenum
        (* #if (GLUT_API_VERSION >= 2) *)
        val GLUT_WINDOW_NUM_SAMPLES : GL.GLenum
        val GLUT_WINDOW_STEREO : GL.GLenum
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 3) *)
        val GLUT_WINDOW_CURSOR : GL.GLenum
        (* #endif *)
        val GLUT_SCREEN_WIDTH : GL.GLenum
        val GLUT_SCREEN_HEIGHT : GL.GLenum
        val GLUT_SCREEN_WIDTH_MM : GL.GLenum
        val GLUT_SCREEN_HEIGHT_MM : GL.GLenum
        val GLUT_MENU_NUM_ITEMS : GL.GLenum
        val GLUT_DISPLAY_MODE_POSSIBLE : GL.GLenum
        val GLUT_INIT_WINDOW_X : GL.GLenum
        val GLUT_INIT_WINDOW_Y : GL.GLenum
        val GLUT_INIT_WINDOW_WIDTH : GL.GLenum
        val GLUT_INIT_WINDOW_HEIGHT : GL.GLenum
        val GLUT_INIT_DISPLAY_MODE : GL.GLenum
        (* #if (GLUT_API_VERSION >= 2) *)
        val GLUT_ELAPSED_TIME : GL.GLenum
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 13) *)
        val GLUT_WINDOW_FORMAT_ID : GL.GLenum
        (* #endif *)

        (* #if (GLUT_API_VERSION >= 2) *)
        (* glutDeviceGet parameters. *)
        val GLUT_HAS_KEYBOARD : GL.GLenum
        val GLUT_HAS_MOUSE : GL.GLenum
        val GLUT_HAS_SPACEBALL : GL.GLenum
        val GLUT_HAS_DIAL_AND_BUTTON_BOX : GL.GLenum
        val GLUT_HAS_TABLET : GL.GLenum
        val GLUT_NUM_MOUSE_BUTTONS : GL.GLenum
        val GLUT_NUM_SPACEBALL_BUTTONS : GL.GLenum
        val GLUT_NUM_BUTTON_BOX_BUTTONS : GL.GLenum
        val GLUT_NUM_DIALS : GL.GLenum
        val GLUT_NUM_TABLET_BUTTONS : GL.GLenum
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 13) *)
        val GLUT_DEVICE_IGNORE_KEY_REPEAT : GL.GLenum
        val GLUT_DEVICE_KEY_REPEAT : GL.GLenum
        val GLUT_HAS_JOYSTICK : GL.GLenum
        val GLUT_OWNS_JOYSTICK : GL.GLenum
        val GLUT_JOYSTICK_BUTTONS : GL.GLenum
        val GLUT_JOYSTICK_AXES : GL.GLenum
        val GLUT_JOYSTICK_POLL_RATE : GL.GLenum
        (* #endif *)

        (* #if (GLUT_API_VERSION >= 3) *)
        (* glutLayerGet parameters. *)
        val GLUT_OVERLAY_POSSIBLE : GL.GLenum
        val GLUT_LAYER_IN_USE : GL.GLenum
        val GLUT_HAS_OVERLAY : GL.GLenum
        val GLUT_TRANSPARENT_INDEX : GL.GLenum
        val GLUT_NORMAL_DAMAGED : GL.GLenum
        val GLUT_OVERLAY_DAMAGED : GL.GLenum

        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9) *)
        (* glutVideoResizeGet parameters. *)
        val GLUT_VIDEO_RESIZE_POSSIBLE : GL.GLenum
        val GLUT_VIDEO_RESIZE_IN_USE : GL.GLenum
        val GLUT_VIDEO_RESIZE_X_DELTA : GL.GLenum
        val GLUT_VIDEO_RESIZE_Y_DELTA : GL.GLenum
        val GLUT_VIDEO_RESIZE_WIDTH_DELTA : GL.GLenum
        val GLUT_VIDEO_RESIZE_HEIGHT_DELTA : GL.GLenum
        val GLUT_VIDEO_RESIZE_X : GL.GLenum
        val GLUT_VIDEO_RESIZE_Y : GL.GLenum
        val GLUT_VIDEO_RESIZE_WIDTH : GL.GLenum
        val GLUT_VIDEO_RESIZE_HEIGHT : GL.GLenum
        (* #endif *)

        (* glutGetModifiers return mask. *)
        val GLUT_ACTIVE_SHIFT : GL.GLenum
        val GLUT_ACTIVE_CTRL : GL.GLenum
        val GLUT_ACTIVE_ALT : GL.GLenum

        (* glutSetCursor parameters. *)
        (* Basic arrows. *)
        val GLUT_CURSOR_RIGHT_ARROW : GL.GLenum
        val GLUT_CURSOR_LEFT_ARROW : GL.GLenum
        (* Symbolic cursor shapes. *)
        val GLUT_CURSOR_INFO : GL.GLenum
        val GLUT_CURSOR_DESTROY : GL.GLenum
        val GLUT_CURSOR_HELP : GL.GLenum
        val GLUT_CURSOR_CYCLE : GL.GLenum
        val GLUT_CURSOR_SPRAY : GL.GLenum
        val GLUT_CURSOR_WAIT : GL.GLenum
        val GLUT_CURSOR_TEXT : GL.GLenum
        val GLUT_CURSOR_CROSSHAIR : GL.GLenum
        (* Directional cursors. *)
        val GLUT_CURSOR_UP_DOWN : GL.GLenum
        val GLUT_CURSOR_LEFT_RIGHT : GL.GLenum
        (* Sizing cursors. *)
        val GLUT_CURSOR_TOP_SIDE : GL.GLenum
        val GLUT_CURSOR_BOTTOM_SIDE : GL.GLenum
        val GLUT_CURSOR_LEFT_SIDE : GL.GLenum
        val GLUT_CURSOR_RIGHT_SIDE : GL.GLenum
        val GLUT_CURSOR_TOP_LEFT_CORNER : GL.GLenum
        val GLUT_CURSOR_TOP_RIGHT_CORNER : GL.GLenum
        val GLUT_CURSOR_BOTTOM_RIGHT_CORNER : GL.GLenum
        val GLUT_CURSOR_BOTTOM_LEFT_CORNER : GL.GLenum
        (* Inherit from parent window. *)
        val GLUT_CURSOR_INHERIT : GL.GLenum
        (* Blank cursor. *)
        val GLUT_CURSOR_NONE : GL.GLenum
        (* Fullscreen crosshair (if available). *)
        val GLUT_CURSOR_FULL_CROSSHAIR : GL.GLenum
        (* #endif *)

        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 13) *)
        (* GLUT device control sub-API. *)
        (* glutSetKeyRepeat modes. *)
        val GLUT_KEY_REPEAT_OFF : GL.GLenum
        val GLUT_KEY_REPEAT_ON : GL.GLenum
        val GLUT_KEY_REPEAT_DEFAULT : GL.GLenum

        (* Joystick button masks. *)
        val GLUT_JOYSTICK_BUTTON_A : GL.GLenum
        val GLUT_JOYSTICK_BUTTON_B : GL.GLenum
        val GLUT_JOYSTICK_BUTTON_C : GL.GLenum
        val GLUT_JOYSTICK_BUTTON_D : GL.GLenum

        (* GLUT game mode sub-API. *)
        (* glutGameModeGet. *)
        val GLUT_GAME_MODE_ACTIVE : GL.GLenum
        val GLUT_GAME_MODE_POSSIBLE : GL.GLenum
        val GLUT_GAME_MODE_WIDTH : GL.GLenum
        val GLUT_GAME_MODE_HEIGHT : GL.GLenum
        val GLUT_GAME_MODE_PIXEL_DEPTH : GL.GLenum
        val GLUT_GAME_MODE_REFRESH_RATE : GL.GLenum
        val GLUT_GAME_MODE_DISPLAY_CHANGED : GL.GLenum
        val glutCreateMenu : (int -> unit) -> int
        val glutDestroyMenu : int -> unit
        val glutGetMenu : unit -> int
        val glutSetMenu : int -> unit
        val glutAddMenuEntry : string -> int -> unit
        val glutAddSubMenu : string -> int -> unit
        val glutChangeToMenuEntry : int -> string -> int -> unit
        val glutChangeToSubMenu : int -> string -> int -> unit
        val glutRemoveMenuItem : int -> unit
        val glutAttachMenu : GL.GLenum -> unit
        val glutDetachMenu : GL.GLenum -> unit

        val glutDisplayFunc: (unit -> unit) -> unit;
        val glutIdleFunc : (unit -> unit ) -> unit ;
        val glutReshapeFunc : (int * int -> unit) -> unit ;
        (*val glutKeyboardFunc : (char * int * int -> unit) -> unit ;*)
        val glutSpecialFunc : (int * int * int -> unit ) -> unit ;
        val glutVisibilityFunc : (Word32.word -> unit ) -> unit

        val glutInit: unit -> unit;
        val glutInitDisplayMode : GLenum -> unit
        (*val glutInit: int -> string list -> unit;*)
        val glutInitWindowPosition : int -> int -> unit
        val glutInitWindowSize : int -> int -> unit
        val glutCreateWindow: string -> int;
        val glutMainLoop: unit -> unit;
        val glutBitmapCharacter : glutfont -> char -> unit
        val glutPostRedisplay : unit -> unit
        val glutStrokeCharacter : glutfont -> char -> unit
        val glutSolidSphere : GLdouble -> int -> int -> unit
        val glutSolidIcosahedron : unit -> unit
        val glutSwapBuffers: unit -> unit;
    end

open GL

structure GLUT :> GLUT =
    struct
        type glutfont = MLton.Pointer.t

        (* Display mode bit masks. *)
        val GLUT_RGB = 0w0
        val GLUT_RGBA = GLUT_RGB
        val GLUT_INDEX = 0w1
        val GLUT_SINGLE = 0w0
        val GLUT_DOUBLE = 0w2
        val GLUT_ACCUM = 0w4
        val GLUT_ALPHA = 0w8
        val GLUT_DEPTH = 0w16
        val GLUT_STENCIL = 0w32
        (* #if (GLUT_API_VERSION >= 0w2) *)
        val GLUT_MULTISAMPLE = 0w128
        val GLUT_STEREO = 0w256
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 0w3) *)
        val GLUT_LUMINANCE = 0w512
        (* #endif *)

        (* Mouse buttons. *)
        val GLUT_LEFT_BUTTON = 0w0
        val GLUT_MIDDLE_BUTTON = 0w1
        val GLUT_RIGHT_BUTTON = 0w2

        (* Mouse button state. *)
        val GLUT_DOWN = 0w0
        val GLUT_UP = 0w1

        (* #if (GLUT_API_VERSION >= 0w2) *)
        (* function keys *)
        val GLUT_KEY_F1 = 0w1
        val GLUT_KEY_F2 = 0w2
        val GLUT_KEY_F3 = 0w3
        val GLUT_KEY_F4 = 0w4
        val GLUT_KEY_F5 = 0w5
        val GLUT_KEY_F6 = 0w6
        val GLUT_KEY_F7 = 0w7
        val GLUT_KEY_F8 = 0w8
        val GLUT_KEY_F9 = 0w9
        val GLUT_KEY_F10 = 0w10
        val GLUT_KEY_F11 = 0w11
        val GLUT_KEY_F12 = 0w12
        (* directional keys *)
        val GLUT_KEY_LEFT = 0w100
        val GLUT_KEY_UP = 0w101
        val GLUT_KEY_RIGHT = 0w102
        val GLUT_KEY_DOWN = 0w103
        val GLUT_KEY_PAGE_UP = 0w104
        val GLUT_KEY_PAGE_DOWN = 0w105
        val GLUT_KEY_HOME = 0w106
        val GLUT_KEY_END = 0w107
        val GLUT_KEY_INSERT = 0w108
        (* #endif *)

        (* Entry/exit state. *)
        val GLUT_LEFT = 0w0
        val GLUT_ENTERED = 0w1

        (* Menu usage state. *)
        val GLUT_MENU_NOT_IN_USE = 0w0
        val GLUT_MENU_IN_USE = 0w1

        (* Visibility state. *)
        val GLUT_NOT_VISIBLE = 0w0
        val GLUT_VISIBLE = 0w1

        (* Window status state. *)
        val GLUT_HIDDEN = 0w0
        val GLUT_FULLY_RETAINED = 0w1
        val GLUT_PARTIALLY_RETAINED = 0w2
        val GLUT_FULLY_COVERED = 0w3

        (* Color index component selection values. *)
        val GLUT_RED = 0w0
        val GLUT_GREEN = 0w1
        val GLUT_BLUE = 0w2

        (* Layers for use. *)
        val GLUT_NORMAL = 0w0
        val GLUT_OVERLAY = 0w1

        (* glutGet parameters. *)
        val GLUT_WINDOW_X = 0w100
        val GLUT_WINDOW_Y = 0w101
        val GLUT_WINDOW_WIDTH = 0w102
        val GLUT_WINDOW_HEIGHT = 0w103
        val GLUT_WINDOW_BUFFER_SIZE = 0w104
        val GLUT_WINDOW_STENCIL_SIZE = 0w105
        val GLUT_WINDOW_DEPTH_SIZE = 0w106
        val GLUT_WINDOW_RED_SIZE = 0w107
        val GLUT_WINDOW_GREEN_SIZE = 0w108
        val GLUT_WINDOW_BLUE_SIZE = 0w109
        val GLUT_WINDOW_ALPHA_SIZE = 0w110
        val GLUT_WINDOW_ACCUM_RED_SIZE = 0w111
        val GLUT_WINDOW_ACCUM_GREEN_SIZE = 0w112
        val GLUT_WINDOW_ACCUM_BLUE_SIZE = 0w113
        val GLUT_WINDOW_ACCUM_ALPHA_SIZE = 0w114
        val GLUT_WINDOW_DOUBLEBUFFER = 0w115
        val GLUT_WINDOW_RGBA = 0w116
        val GLUT_WINDOW_PARENT = 0w117
        val GLUT_WINDOW_NUM_CHILDREN = 0w118
        val GLUT_WINDOW_COLORMAP_SIZE = 0w119
        (* #if (GLUT_API_VERSION >= 0w2) *)
        val GLUT_WINDOW_NUM_SAMPLES = 0w120
        val GLUT_WINDOW_STEREO = 0w121
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 0w3) *)
        val GLUT_WINDOW_CURSOR = 0w122
        (* #endif *)
        val GLUT_SCREEN_WIDTH = 0w200
        val GLUT_SCREEN_HEIGHT = 0w201
        val GLUT_SCREEN_WIDTH_MM = 0w202
        val GLUT_SCREEN_HEIGHT_MM = 0w203
        val GLUT_MENU_NUM_ITEMS = 0w300
        val GLUT_DISPLAY_MODE_POSSIBLE = 0w400
        val GLUT_INIT_WINDOW_X = 0w500
        val GLUT_INIT_WINDOW_Y = 0w501
        val GLUT_INIT_WINDOW_WIDTH = 0w502
        val GLUT_INIT_WINDOW_HEIGHT = 0w503
        val GLUT_INIT_DISPLAY_MODE = 0w504
        (* #if (GLUT_API_VERSION >= 0w2) *)
        val GLUT_ELAPSED_TIME = 0w700
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 0w13) *)
        val GLUT_WINDOW_FORMAT_ID = 0w123
        (* #endif *)

        (* #if (GLUT_API_VERSION >= 0w2) *)
        (* glutDeviceGet parameters. *)
        val GLUT_HAS_KEYBOARD = 0w600
        val GLUT_HAS_MOUSE = 0w601
        val GLUT_HAS_SPACEBALL = 0w602
        val GLUT_HAS_DIAL_AND_BUTTON_BOX = 0w603
        val GLUT_HAS_TABLET = 0w604
        val GLUT_NUM_MOUSE_BUTTONS = 0w605
        val GLUT_NUM_SPACEBALL_BUTTONS = 0w606
        val GLUT_NUM_BUTTON_BOX_BUTTONS = 0w607
        val GLUT_NUM_DIALS = 0w608
        val GLUT_NUM_TABLET_BUTTONS = 0w609
        (* #endif *)
        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 0w13) *)
        val GLUT_DEVICE_IGNORE_KEY_REPEAT = 0w610
        val GLUT_DEVICE_KEY_REPEAT = 0w611
        val GLUT_HAS_JOYSTICK = 0w612
        val GLUT_OWNS_JOYSTICK = 0w613
        val GLUT_JOYSTICK_BUTTONS = 0w614
        val GLUT_JOYSTICK_AXES = 0w615
        val GLUT_JOYSTICK_POLL_RATE = 0w616
        (* #endif *)

        (* #if (GLUT_API_VERSION >= 0w3) *)
        (* glutLayerGet parameters. *)
        val GLUT_OVERLAY_POSSIBLE = 0w800
        val GLUT_LAYER_IN_USE = 0w801
        val GLUT_HAS_OVERLAY = 0w802
        val GLUT_TRANSPARENT_INDEX = 0w803
        val GLUT_NORMAL_DAMAGED = 0w804
        val GLUT_OVERLAY_DAMAGED = 0w805

        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 0w9) *)
        (* glutVideoResizeGet parameters. *)
        val GLUT_VIDEO_RESIZE_POSSIBLE = 0w900
        val GLUT_VIDEO_RESIZE_IN_USE = 0w901
        val GLUT_VIDEO_RESIZE_X_DELTA = 0w902
        val GLUT_VIDEO_RESIZE_Y_DELTA = 0w903
        val GLUT_VIDEO_RESIZE_WIDTH_DELTA = 0w904
        val GLUT_VIDEO_RESIZE_HEIGHT_DELTA = 0w905
        val GLUT_VIDEO_RESIZE_X = 0w906
        val GLUT_VIDEO_RESIZE_Y = 0w907
        val GLUT_VIDEO_RESIZE_WIDTH = 0w908
        val GLUT_VIDEO_RESIZE_HEIGHT = 0w909
        (* #endif *)

        (* glutGetModifiers return mask. *)
        val GLUT_ACTIVE_SHIFT = 0w1
        val GLUT_ACTIVE_CTRL = 0w2
        val GLUT_ACTIVE_ALT = 0w4

        (* glutSetCursor parameters. *)
        (* Basic arrows. *)
        val GLUT_CURSOR_RIGHT_ARROW = 0w0
        val GLUT_CURSOR_LEFT_ARROW = 0w1
        (* Symbolic cursor shapes. *)
        val GLUT_CURSOR_INFO = 0w2
        val GLUT_CURSOR_DESTROY = 0w3
        val GLUT_CURSOR_HELP = 0w4
        val GLUT_CURSOR_CYCLE = 0w5
        val GLUT_CURSOR_SPRAY = 0w6
        val GLUT_CURSOR_WAIT = 0w7
        val GLUT_CURSOR_TEXT = 0w8
        val GLUT_CURSOR_CROSSHAIR = 0w9
        (* Directional cursors. *)
        val GLUT_CURSOR_UP_DOWN = 0w10
        val GLUT_CURSOR_LEFT_RIGHT = 0w11
        (* Sizing cursors. *)
        val GLUT_CURSOR_TOP_SIDE = 0w12
        val GLUT_CURSOR_BOTTOM_SIDE = 0w13
        val GLUT_CURSOR_LEFT_SIDE = 0w14
        val GLUT_CURSOR_RIGHT_SIDE = 0w15
        val GLUT_CURSOR_TOP_LEFT_CORNER = 0w16
        val GLUT_CURSOR_TOP_RIGHT_CORNER =0w17
        val GLUT_CURSOR_BOTTOM_RIGHT_CORNER =0w18
        val GLUT_CURSOR_BOTTOM_LEFT_CORNER =0w19
        (* Inherit from parent window. *)
        val GLUT_CURSOR_INHERIT = 0w100
        (* Blank cursor. *)
        val GLUT_CURSOR_NONE = 0w101
        (* Fullscreen crosshair (if available). *)
        val GLUT_CURSOR_FULL_CROSSHAIR =0w102
        (* #endif *)

        (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 0w13) *)
        (* GLUT device control sub-API. *)
        (* glutSetKeyRepeat modes. *)
        val GLUT_KEY_REPEAT_OFF = 0w0
        val GLUT_KEY_REPEAT_ON = 0w1
        val GLUT_KEY_REPEAT_DEFAULT = 0w2

        (* Joystick button masks. *)
        val GLUT_JOYSTICK_BUTTON_A = 0w1
        val GLUT_JOYSTICK_BUTTON_B = 0w2
        val GLUT_JOYSTICK_BUTTON_C = 0w4
        val GLUT_JOYSTICK_BUTTON_D = 0w8

        (* GLUT game mode sub-API. *)
        (* glutGameModeGet. *)
        val GLUT_GAME_MODE_ACTIVE = 0w0
        val GLUT_GAME_MODE_POSSIBLE = 0w1
        val GLUT_GAME_MODE_WIDTH = 0w2
        val GLUT_GAME_MODE_HEIGHT = 0w3
        val GLUT_GAME_MODE_PIXEL_DEPTH = 0w4
        val GLUT_GAME_MODE_REFRESH_RATE = 0w5
        val GLUT_GAME_MODE_DISPLAY_CHANGED = 0w6

        local






            (* Create Menu callback *)
            val gCreateMenuFA = _export "glutCreateMenuArgument": int -> unit;
            val callGCreateMenuF = _import "callGlutCreateMenu": unit -> int;

            (* Display function callback *)
            val gDisplayFA = _export "glutDisplayFuncArgument": unit -> unit;
            val callGDisplayF = _import "callGlutDisplayFunc": unit -> unit;

            (* Idle function callback *)
            val gIdleFA = _export "glutIdleFuncArgument": unit -> unit;
            val callGIdleF = _import "callGlutIdleFunc": unit -> unit;

            (* Reshape function callback *)
            val gReshapeFA = _export "glutReshapeFuncArgument": int * int -> unit;
            val callGReshapeF = _import "callGlutReshapeFunc": unit -> unit;

            (* Keyboard function callback *)
            (*val gKbdFA = _export "glutKeyboardFuncArgument": char * int * int -> unit;
            val callGKbdF = _import "callGlutKeyboardFunc": unit -> unit;*)

            (* Special function callback *)
            val gSpecFA = _export "glutSpecialFuncArgument": int * int * int -> unit;
            val callGSpecF = _import "callGlutSpecialFunc": unit -> unit;

            (* Visibility function callback *)
            val gVisibilityFA = _export "glutVisibilityFuncArgument": Word32.word -> unit;
            val callGVisibilityF = _import "callGlutVisibilityFunc": unit -> unit;


            (* GLUT initialisation *)
            val cGI = _import "callGlutInit": unit -> unit;

        in
            (* Stroke font constants (use these in GLUT program). *)
            val c_GLUT_STROKE_ROMAN = _import "mlton_glut_stroke_roman" : unit -> glutfont;
            val GLUT_STROKE_ROMAN = c_GLUT_STROKE_ROMAN()

            val c_GLUT_STROKE_MONO_ROMAN = _import "mlton_glut_stroke_mono_roman" : unit -> glutfont;
            val GLUT_STROKE_MONO_ROMAN = c_GLUT_STROKE_MONO_ROMAN()

            (* Bitmap font constants (use these in GLUT program). *)
            val c_GLUT_BITMAP_9_BY_15 = _import "mlton_glut_bitmap_9_by_15" : unit -> glutfont;
            val GLUT_BITMAP_9_BY_15 = c_GLUT_BITMAP_9_BY_15()

            val c_GLUT_BITMAP_8_BY_13 = _import "mlton_glut_bitmap_8_by_13" : unit -> glutfont;
            val GLUT_BITMAP_8_BY_13 = c_GLUT_BITMAP_8_BY_13()

            val c_GLUT_BITMAP_TIMES_ROMAN_10 = _import "mlton_glut_bitmap_times_roman_10" : unit -> glutfont;
            val GLUT_BITMAP_TIMES_ROMAN_10 = c_GLUT_BITMAP_TIMES_ROMAN_10()

            val c_GLUT_BITMAP_TIMES_ROMAN_24 = _import "mlton_glut_bitmap_times_roman_24" : unit -> glutfont;
            val GLUT_BITMAP_TIMES_ROMAN_24 = c_GLUT_BITMAP_TIMES_ROMAN_24()

            val c_GLUT_BITMAP_HELVETICA_10 = _import "mlton_glut_bitmap_helvetica_10" : unit -> glutfont;
            val GLUT_BITMAP_HELVETICA_10 = c_GLUT_BITMAP_HELVETICA_10()

            val c_GLUT_BITMAP_HELVETICA_12 = _import "mlton_glut_bitmap_helvetica_12" : unit -> glutfont;
            val GLUT_BITMAP_HELVETICA_12 = c_GLUT_BITMAP_HELVETICA_12()

            val c_GLUT_BITMAP_HELVETICA_18 = _import "mlton_glut_bitmap_helvetica_18" : unit -> glutfont;
            val GLUT_BITMAP_HELVETICA_18 = c_GLUT_BITMAP_HELVETICA_18()

            fun glutCreateMenu (cm : int -> unit) = ( gCreateMenuFA cm; callGCreateMenuF ()) : int;
            fun glutDisplayFunc (display: unit -> unit) = (gDisplayFA display; callGDisplayF ())
            fun glutIdleFunc (idle: unit -> unit) = (gIdleFA idle; callGIdleF ())
            fun glutReshapeFunc (reshape: int * int -> unit) = ( gReshapeFA reshape; callGReshapeF ())
            (*fun glutKeyboardFunc (kbd: char * int * int -> unit) = ( gKbdFA kbd; callGKbdF ())*)
            fun glutSpecialFunc (kbd: int * int * int -> unit) = ( gSpecFA kbd; callGSpecF ())
            fun glutVisibilityFunc (vis: Word32.word -> unit) = ( gVisibilityFA vis; callGVisibilityF ())

            val c_glutDestroyMenu = _import "glutDestroyMenu" stdcall: int -> unit;
            fun glutDestroyMenu (a:int) = c_glutDestroyMenu (a): unit;

            val c_glutGetMenu = _import "glutGetMenu" stdcall: unit -> int;
            fun glutGetMenu () = c_glutGetMenu () : int;

            val c_glutSetMenu = _import "glutSetMenu" stdcall: int -> unit ;
            fun glutSetMenu (a:int) = c_glutSetMenu (a) : unit;

            val c_glutAddMenuEntry = _import "glutAddMenuEntry" stdcall: string * int -> unit ;
            fun glutAddMenuEntry (a:string) (b:int) = c_glutAddMenuEntry (a,b) : unit;

            val c_glutAddSubMenu = _import "glutAddSubMenu" stdcall: string * int -> unit ;
            fun glutAddSubMenu (a:string) (b:int) = c_glutAddSubMenu (a,b) : unit;

            val c_glutChangeToMenuEntry = _import "glutChangeToMenuEntry" stdcall: int * string * int -> unit ;
            fun glutChangeToMenuEntry (c:int) (a:string) (b:int) = c_glutChangeToMenuEntry (c,a,b) : unit;

            val c_glutChangeToSubMenu = _import "glutChangeToSubMenu" stdcall: int * string * int -> unit ;
            fun glutChangeToSubMenu (c:int) (a:string) (b:int) = c_glutChangeToSubMenu (c,a,b) : unit;

            val c_glutRemoveMenuItem = _import "glutRemoveMenuItem" stdcall: int -> unit ;
            fun glutRemoveMenuItem (a:int) = c_glutRemoveMenuItem (a) : unit;

            val c_glutAttachMenu = _import "glutAttachMenu" stdcall: GL.GLenum -> unit ;
            fun glutAttachMenu (a:GLenum) = c_glutAttachMenu (a): unit;

            val c_glutDetachMenu = _import "glutDetachMenu" stdcall: GL.GLenum -> unit ;
            fun glutDetachMenu (a:GLenum) = c_glutDetachMenu (a) : unit;

            fun glutInit () = cGI ()

            (*val init = _import "glutInit" : int -> string list -> unit;*)
            val c_glutInitDisplayMode = _import "glutInitDisplayMode" stdcall: GL.GLenum -> unit;
            fun glutInitDisplayMode (a:GL.GLenum) = c_glutInitDisplayMode (a) : unit

            (* #if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9)*)
            val c_glutInitDisplayString = _import "glutInitDisplayString" stdcall: string -> unit;
            fun glutInitDisplayString (a:string) = c_glutInitDisplayString (a) : unit

            val c_glutInitWindowPosition = _import "glutInitWindowPosition" stdcall: int * int -> unit ;
            fun glutInitWindowPosition (a:int) (b:int) = c_glutInitWindowPosition (a, b) :unit

            val c_glutInitWindowSize = _import "glutInitWindowSize" stdcall: int * int -> unit;
            fun glutInitWindowSize (a:int) (b:int) = c_glutInitWindowSize (a, b) :unit

            val glutCreateWindow = _import "glutCreateWindow" stdcall: string -> int;

            val glutMainLoop = _import "glutMainLoop" stdcall: unit -> unit;

            val glutPostRedisplay = _import "glutPostRedisplay" stdcall: unit -> unit;

            val c_glutBitmapCharacter = _import "glutBitmapCharacter" stdcall: glutfont * int -> unit;
            fun glutBitmapCharacter (a:glutfont) (b:char) =
                let val c = ord (b)
                in c_glutBitmapCharacter (a,c) end

            (*val c_glutBitmapWidth : glutfont -> int -> int =
                Dynlib.app2 (Dynlib.dlsym dlh "mosml_glutBitmapWidth")*)

            val c_glutStrokeCharacter = _import "glutStrokeCharacter" stdcall: glutfont * int -> unit;
            fun glutStrokeCharacter (a:glutfont) (b:char) =
                let val c = ord (b)
                in c_glutStrokeCharacter (a,c) end

            val c_glutSolidSphere = _import "glutSolidSphere" stdcall: GLdouble * int * int -> unit;
            fun glutSolidSphere (a:GLdouble) (b:int) (c:int) = c_glutSolidSphere (a,b,c)

            val c_glutSolidIcosahedron = _import "glutSolidIcosahedron" stdcall: unit -> unit;
            fun glutSolidIcosahedron () = c_glutSolidIcosahedron ()

            val glutSwapBuffers = _import "glutSwapBuffers" stdcall: unit -> unit;
        end


    end
