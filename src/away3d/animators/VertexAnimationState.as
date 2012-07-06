package away3d.animators
{
	import away3d.animators.nodes.VertexClipNode;
	import away3d.arcane;
	
	use namespace arcane;
	
	/**
	 * @author robbateman
	 */
	public class VertexAnimationState extends AnimationStateBase implements IAnimationState
	{
		public function VertexAnimationState(rootNode:VertexClipNode)
		{
			super(rootNode);
		}
	}
}