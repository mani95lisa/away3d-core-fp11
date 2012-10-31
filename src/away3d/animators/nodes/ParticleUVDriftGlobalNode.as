package away3d.animators.nodes
{
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleAnimationSetting;
	import away3d.animators.states.ParticleUVDriftGlobalState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	/**
	 * ...
	 */
	public class ParticleUVDriftGlobalNode extends GlobalParticleNodeBase
	{
		public static const NAME:String = "ParticleUVDriftGlobalNode";
		public static const U_AXIS:int = 0;
		public static const V_AXIS:int = 1;
		
		public static const UV_CONSTANT_REGISTER:int = 0;
		
		private var _cycle:Number;
		private var _scale:Number;
		private var _data:Vector.<Number>;
		private var _isScale:Boolean;
		private var _axis:int;

		public function ParticleUVDriftGlobalNode(cycle:Number,scale:Number=1, axis:int=U_AXIS)
		{
			super(NAME, ParticleAnimationSet.POST_PRIORITY + 1);
			_stateClass = ParticleUVDriftGlobalState;
			
			if (scale != 1)_isScale = true;
			
			_cycle = cycle;
			_scale = scale;
			_axis = axis;
			_data = new Vector.<Number>(4, true);
			_data[1] = scale;
			reset();
		}
		
		override public function processAnimationSetting(setting:ParticleAnimationSetting):void
		{
			setting.hasUVNode = true;
		}
		
		public function get renderData():Vector.<Number>
		{
			return _data;
		}
		
		public function get cycle():Number
		{
			return _cycle;
		}
		
		public function set cycle(value:Number):void
		{
			_cycle = value;
			reset();
		}
		
		public function get sclae():Number
		{
			return _scale;
		}
		
		public function get axis():int
		{
			return _axis;
		}
		
		private function reset():void
		{
			_data[0] = Math.PI * 2 / cycle;
		}
		
		
		override public function getAGALUVCode(pass:MaterialPassBase, sharedSetting:ParticleAnimationSetting, animationRegisterCache:AnimationRegisterCache) : String
		{
			var uvParamConst:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, UV_CONSTANT_REGISTER, uvParamConst.index);
	
			var target:ShaderRegisterElement;
			if (_axis == U_AXIS) target = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, "x");
			else target = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, "y");
			
			var sin:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();
			
			var code:String = "";
			
			if (_isScale) code += "mul " + target.toString() + "," + target.toString() + "," + uvParamConst.toString() + ".y\n";
			code += "mul " + sin.toString() + "," + animationRegisterCache.vertexTime.toString() + "," + uvParamConst.toString() + ".x\n";
			code += "sin " + sin.toString() + "," + sin.toString() + "\n";
			code += "add " + target.toString() + "," + target.toString() + "," + sin.toString() + "\n";
			
			return code;
		}
	
	}

}