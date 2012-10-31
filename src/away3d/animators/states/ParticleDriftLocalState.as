package away3d.animators.states
{
	import away3d.animators.data.ParticleRenderParameter;
	import away3d.animators.nodes.ParticleDriftLocalNode;
	import away3d.animators.nodes.ParticleNodeBase;
	import away3d.animators.ParticleAnimator;
	import flash.display3D.Context3DVertexBufferFormat;
	/**
	 * ...
	 */
	public class ParticleDriftLocalState extends ParticleStateBase
	{
		
		public function ParticleDriftLocalState(animator:ParticleAnimator, particleNode:ParticleNodeBase)
		{
			super(animator, particleNode);
		}
		
		
		override public function setRenderState(parameter:ParticleRenderParameter) : void
		{
			var index:int = parameter.animationRegisterCache.getRegisterIndex(particleNode, ParticleDriftLocalNode.DRIFT_STREAM_REGISTER);
			parameter.animationSubGeometry.activateVertexBuffer(index, parameter.animationSubGeometry.getNodeDataOffset(particleNode), parameter.stage3DProxy, Context3DVertexBufferFormat.FLOAT_4);
		}
		
	}

}