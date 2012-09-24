﻿package away3d.core.base
{
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;

	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * The SubGeometry class is a collections of geometric data that describes a triangle mesh. It is owned by a
	 * Geometry instance, and wrapped by a SubMesh in the scene graph.
	 * Several SubGeometries are grouped so they can be rendered with different materials, but still represent a single
	 * object.
	 *
	 * @see away3d.core.base.Geometry
	 * @see away3d.core.base.SubMesh
	 */
	public class SubGeometry implements ISubGeometry
	{
		private var _parentGeometry : Geometry;

		// raw data:
		protected var _vertices : Vector.<Number>;
		protected var _uvs : Vector.<Number>;
		protected var _secondaryUvs : Vector.<Number>;
		protected var _vertexNormals : Vector.<Number>;
		protected var _vertexTangents : Vector.<Number>;
		protected var _indices : Vector.<uint>;
		protected var _faceNormalsData : Vector.<Number>;
		protected var _faceWeights : Vector.<Number>;
		protected var _faceTangents : Vector.<Number>;

		protected var _verticesInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _uvsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _secondaryUvsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _normalsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _tangentsInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);
		protected var _indicesInvalid : Vector.<Boolean> = new Vector.<Boolean>(8, true);

		// buffers:
		protected var _vertexBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _uvBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _secondaryUvBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _vertexNormalBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _vertexTangentBuffer : Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		protected var _indexBuffer : Vector.<IndexBuffer3D> = new Vector.<IndexBuffer3D>(8);

		private var _autoGenerateUVs : Boolean = false;
		private var _autoDeriveVertexNormals : Boolean = true;
		private var _autoDeriveVertexTangents : Boolean = true;
		private var _useFaceWeights : Boolean = false;

		// raw data dirty flags:
		protected var _uvsDirty : Boolean = true;
		protected var _faceNormalsDirty : Boolean = true;
		protected var _faceTangentsDirty : Boolean = true;
		protected var _vertexNormalsDirty : Boolean = true;
		protected var _vertexTangentsDirty : Boolean = true;

		// buffer dirty flags, per context:
		protected var _vertexBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _uvBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _secondaryUvBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _indexBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _vertexNormalBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);
		protected var _vertexTangentBufferContext : Vector.<Context3D> = new Vector.<Context3D>(8);

		protected var _numVertices : uint;
		protected var _numIndices : uint;
		protected var _numTriangles : uint;
		private var _uvScaleV : Number = 1;


		/**
		 * Creates a new SubGeometry object.
		 */
		public function SubGeometry()
		{
		}

		/**
		 * The total amount of vertices in the SubGeometry.
		 */
		public function get numVertices() : uint
		{
			return _numVertices;
		}

		/**
		 * The total amount of triangles in the SubGeometry.
		 */
		public function get numTriangles() : uint
		{
			return _numTriangles;
		}
		
		
		/**
		 * Defines whether a UV buffer should be automatically generated to contain dummy UV coordinates.
		 * Set to true if a geometry lacks UV data but uses a material that requires it, or leave as false
		 * in cases where UV data is explicitly defined or the material does not require UV data.
		*/
		public function get autoGenerateDummyUVs() : Boolean
		{
			return _autoGenerateUVs;
		}
		
		public function set autoGenerateDummyUVs(value : Boolean) : void
		{
			_autoGenerateUVs = value;
			_uvsDirty = value;
		}
		

		/**
		 * True if the vertex normals should be derived from the geometry, false if the vertex normals are set
		 * explicitly.
		 */
		public function get autoDeriveVertexNormals() : Boolean
		{
			return _autoDeriveVertexNormals;
		}

		public function set autoDeriveVertexNormals(value : Boolean) : void
		{
			_autoDeriveVertexNormals = value;

			_vertexNormalsDirty = value;
		}

		/**
		 * Indicates whether or not to take the size of faces into account when auto-deriving vertex normals and tangents.
		 */
		public function get useFaceWeights() : Boolean
		{
			return _useFaceWeights;
		}

		public function set useFaceWeights(value : Boolean) : void
		{
			_useFaceWeights = value;
			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
			_faceNormalsDirty = true;
		}

		/**
		 * True if the vertex tangents should be derived from the geometry, false if the vertex normals are set
		 * explicitly.
		 */
		public function get autoDeriveVertexTangents() : Boolean
		{
			return _autoDeriveVertexTangents;
		}

		public function set autoDeriveVertexTangents(value : Boolean) : void
		{
			_autoDeriveVertexTangents = value;

			_vertexTangentsDirty = value;
		}

		/**
		 * @inheritDoc
		 */
		public function activateVertexBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;
			if (!_vertexBuffer[contextIndex] || _vertexBufferContext[contextIndex] != context) {
				_vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 3);
				_vertexBufferContext[contextIndex] = context;
				_verticesInvalid[contextIndex] = true;
 			}
			if (_verticesInvalid[contextIndex]) {
				_vertexBuffer[contextIndex].uploadFromVector(_vertices, 0, _numVertices);
				_verticesInvalid[contextIndex] = false;
			}

			stage3DProxy.setSimpleVertexBuffer(index, _vertexBuffer[contextIndex], Context3DVertexBufferFormat.FLOAT_3);
		}

		/**
		 * @inheritDoc
		 */
		public function activateUVBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (_autoGenerateUVs && _uvsDirty)
				updateDummyUVs();

			if (!_uvBuffer[contextIndex] || _uvBufferContext[contextIndex] != context) {
				_uvBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 2);
				_uvBufferContext[contextIndex] = context;
				_uvsInvalid[contextIndex] = true;
 			}
			if (_uvsInvalid[contextIndex]) {
				_uvBuffer[contextIndex].uploadFromVector(_uvs, 0, _numVertices);
				_uvsInvalid[contextIndex] = false;
			}

			stage3DProxy.setSimpleVertexBuffer(index, _uvBuffer[contextIndex], Context3DVertexBufferFormat.FLOAT_2);
		}

		/**
		 * @inheritDoc
		 */
		public function activateSecondaryUVBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (!_secondaryUvBuffer[contextIndex] || _secondaryUvBufferContext[contextIndex] != context) {
				_secondaryUvBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 2);
				_secondaryUvBufferContext[contextIndex] = context;
				_secondaryUvsInvalid[contextIndex] = true;
 			}
			if (_secondaryUvsInvalid[contextIndex]) {
				_secondaryUvBuffer[contextIndex].uploadFromVector(_secondaryUvs, 0, _numVertices);
				_secondaryUvsInvalid[contextIndex] = false;
			}

			stage3DProxy.setSimpleVertexBuffer(index, _secondaryUvBuffer[contextIndex], Context3DVertexBufferFormat.FLOAT_2);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex normals.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex normals.
		 */
		public function activateVertexNormalBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (_autoDeriveVertexNormals && _vertexNormalsDirty)
				updateVertexNormals();

			if (!_vertexNormalBuffer[contextIndex] || _vertexNormalBufferContext[contextIndex] != context) {
				_vertexNormalBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 3)
				_vertexNormalBufferContext[contextIndex] = context;
				_normalsInvalid[contextIndex] = true;
 			}
			if (_normalsInvalid[contextIndex]) {
				_vertexNormalBuffer[contextIndex].uploadFromVector(_vertexNormals, 0, _numVertices);
				_normalsInvalid[contextIndex] = false;
			}

			stage3DProxy.setSimpleVertexBuffer(index, _vertexNormalBuffer[contextIndex], Context3DVertexBufferFormat.FLOAT_3);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains vertex tangents.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains vertex tangents.
		 */
		public function activateVertexTangentBuffer(index : int, stage3DProxy : Stage3DProxy) : void
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (_vertexTangentsDirty)
				updateVertexTangents();

			if (!_vertexTangentBuffer[contextIndex] || _vertexTangentBufferContext[contextIndex] != context) {
				_vertexTangentBuffer[contextIndex] = context.createVertexBuffer(_numVertices, 3)
				_vertexTangentBufferContext[contextIndex] = context;
				_tangentsInvalid[contextIndex] = true;
 			}
			if (_tangentsInvalid[contextIndex]) {
				_vertexTangentBuffer[contextIndex].uploadFromVector(_vertexTangents, 0, _numVertices);
				_tangentsInvalid[contextIndex] = false;
			}
			stage3DProxy.setSimpleVertexBuffer(index, _vertexTangentBuffer[contextIndex], Context3DVertexBufferFormat.FLOAT_3);
		}

		/**
		 * Retrieves the VertexBuffer3D object that contains triangle indices.
		 * @param context The Context3D for which we request the buffer
		 * @return The VertexBuffer3D object that contains triangle indices.
		 */
		public function getIndexBuffer(stage3DProxy : Stage3DProxy) : IndexBuffer3D
		{
			var contextIndex : int = stage3DProxy._stage3DIndex;
			var context : Context3D = stage3DProxy._context3D;

			if (!_indexBuffer[contextIndex] || _indexBufferContext[contextIndex] != context) {
				_indexBuffer[contextIndex] = context.createIndexBuffer(_numIndices);
				_indexBufferContext[contextIndex] = context;
				_indicesInvalid[contextIndex] = true;
 			}
			if (_indicesInvalid[contextIndex]) {
				_indexBuffer[contextIndex].uploadFromVector(_indices, 0, _numIndices);
				_indicesInvalid[contextIndex] = false;
			}

			return _indexBuffer[contextIndex];
		}

		public function applyTransformation(transform:Matrix3D):void
		{
			var len : uint = _vertices.length/3;
			var i:uint, i0:uint, i1:uint, i2:uint;
			var v3:Vector3D = new Vector3D();

			var bakeNormals:Boolean = _vertexNormals != null;
			var bakeTangents:Boolean = _vertexTangents != null;

			for (i = 0; i < len; ++i) {

				i0 = 3 * i;
				i1 = i0 + 1;
				i2 = i0 + 2;

				// bake position
				v3.x = _vertices[i0];
				v3.y = _vertices[i1];
				v3.z = _vertices[i2];
				v3 = transform.transformVector(v3);
				_vertices[i0] = v3.x;
				_vertices[i1] = v3.y;
				_vertices[i2] = v3.z;

				// bake normal
				if(bakeNormals)
				{
					v3.x = _vertexNormals[i0];
					v3.y = _vertexNormals[i1];
					v3.z = _vertexNormals[i2];
					v3 = transform.deltaTransformVector(v3);
					_vertexNormals[i0] = v3.x;
					_vertexNormals[i1] = v3.y;
					_vertexNormals[i2] = v3.z;
				}

				// bake tangent
				if(bakeTangents)
				{
					v3.x = _vertexTangents[i0];
					v3.y = _vertexTangents[i1];
					v3.z = _vertexTangents[i2];
					v3 = transform.deltaTransformVector(v3);
					_vertexTangents[i0] = v3.x;
					_vertexTangents[i1] = v3.y;
					_vertexTangents[i2] = v3.z;
				}
			}
		}

		/**
		 * Clones the current object
		 * @return An exact duplicate of the current object.
		 */
		public function clone() : SubGeometry
		{
			var clone : SubGeometry = new SubGeometry();
			clone.updateVertexData(_vertices.concat());
			clone.updateUVData(_uvs.concat());
			clone.updateIndexData(_indices.concat());
			if (_secondaryUvs) clone.updateSecondaryUVData(_secondaryUvs.concat());
			if (!_autoDeriveVertexNormals) clone.updateVertexNormalData(_vertexNormals.concat());
			if (!_autoDeriveVertexTangents) clone.updateVertexTangentData(_vertexTangents.concat());
			return clone;
		}

		/**
		 * Scales the geometry.
		 * @param scale The amount by which to scale.
		 */
		public function scale(scale : Number):void
		{
			var len : uint = _vertices.length;
			for (var i : uint = 0; i < len; ++i)
				_vertices[i] *= scale;
			invalidateBuffers(_verticesInvalid);
		}

		/**
		 * Scales the uv coordinates
		 * @param scaleU The amount by which to scale on the u axis. Default is 1;
		 * @param scaleV The amount by which to scale on the v axis. Default is 1;
		 */
		private var _scaleU : Number = 1;
		private var _scaleV : Number = 1;

		public function get scaleU():Number
		{
			return _scaleU;
		}
		
		public function get scaleV():Number
		{
			return _scaleV;
		}
		 
		public function scaleUV(scaleU : Number = 1, scaleV : Number = 1):void
		{
			for (var i : uint = 0; i < _uvs.length;++i) {
				_uvs[i] /= _scaleU;
				_uvs[i] *= scaleU;
				i++;
				_uvs[i] /= _scaleV;
				_uvs[i] *= scaleV;
			}
			
			_scaleU = scaleU;
			_scaleV = scaleV;
			 
			invalidateBuffers(_uvsInvalid);
		}

		/**
		 * Clears all resources used by the SubGeometry object.
		 */
		public function dispose() : void
		{
			disposeAllVertexBuffers();
			disposeIndexBuffers(_indexBuffer);
			_vertexBuffer = null;
			_vertexNormalBuffer = null;
			_uvBuffer = null;
			_secondaryUvBuffer = null;
			_vertexTangentBuffer = null;
			_indexBuffer = null;
			_vertices = null;
			_uvs = null;
			_secondaryUvs = null;
			_vertexNormals = null;
			_vertexTangents = null;
			_indices = null;
			_faceNormalsData = null;
			_faceWeights = null;
			_faceTangents = null;
			_vertexBufferContext = null;
			_uvBufferContext = null;
			_secondaryUvBufferContext = null;
			_indexBufferContext = null;
			_vertexNormalBufferContext = null;
			_vertexTangentBufferContext = null;
		}

		protected function disposeAllVertexBuffers() : void
		{
			disposeVertexBuffers(_vertexBuffer);
			disposeVertexBuffers(_vertexNormalBuffer);
			disposeVertexBuffers(_uvBuffer);
			disposeVertexBuffers(_secondaryUvBuffer);
			disposeVertexBuffers(_vertexTangentBuffer);
		}

		/**
		 * The raw vertex position data.
		 */
		public function get vertexData() : Vector.<Number>
		{
			return _vertices;
		}

		/**
		 * Updates the vertex data of the SubGeometry.
		 * @param vertices The new vertex data to upload.
		 */
		public function updateVertexData(vertices : Vector.<Number>) : void
		{
			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;

			_faceNormalsDirty = true;

			_vertices = vertices;
			var numVertices : int = vertices.length / 3;
			if (numVertices != _numVertices) disposeAllVertexBuffers();
			_numVertices = numVertices;

            invalidateBuffers(_verticesInvalid);

			invalidateBounds();
		}

		private function invalidateBounds() : void
		{
			if (_parentGeometry) _parentGeometry.invalidateBounds(this);
		}

		/**
		 * The raw texture coordinate data.
		 */
		public function get UVData() : Vector.<Number>
		{
			return _uvs;
		}

		public function get secondaryUVData() : Vector.<Number>
		{
			return _secondaryUvs;
		}

		/**
		 * Updates the uv coordinates of the SubGeometry.
		 * @param uvs The uv coordinates to upload.
		 */
		public function updateUVData(uvs : Vector.<Number>) : void
		{
			// normals don't get dirty from this
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
			_faceTangentsDirty = true;
			_uvs = uvs;
			invalidateBuffers(_uvsInvalid);
		}

		public function updateSecondaryUVData(uvs : Vector.<Number>) : void
		{
			_secondaryUvs = uvs;
			invalidateBuffers(_secondaryUvsInvalid);
		}

		/**
		 * The raw vertex normal data.
		 */
		public function get vertexNormalData() : Vector.<Number>
		{
			if (_autoDeriveVertexNormals && _vertexNormalsDirty) updateVertexNormals();
			return _vertexNormals;
		}

		/**
		 * Updates the vertex normals of the SubGeometry. When updating the vertex normals like this,
		 * autoDeriveVertexNormals will be set to false and vertex normals will no longer be calculated automatically.
		 * @param vertexNormals The vertex normals to upload.
		 */
		public function updateVertexNormalData(vertexNormals : Vector.<Number>) : void
		{
			_vertexNormalsDirty = false;
			_autoDeriveVertexNormals = (vertexNormals == null);
			_vertexNormals = vertexNormals;
			invalidateBuffers(_normalsInvalid);
		}

		/**
		 * The raw vertex tangent data.
		 *
		 * @private
		 */
		public function get vertexTangentData() : Vector.<Number>
		{
			if (_autoDeriveVertexTangents && _vertexTangentsDirty) updateVertexTangents();
			return _vertexTangents;
		}

		/**
		 * Updates the vertex tangents of the SubGeometry. When updating the vertex tangents like this,
		 * autoDeriveVertexTangents will be set to false and vertex tangents will no longer be calculated automatically.
		 * @param vertexTangents The vertex tangents to upload.
		 */
		public function updateVertexTangentData(vertexTangents : Vector.<Number>) : void
		{
			_vertexTangentsDirty = false;
			_autoDeriveVertexTangents = (vertexTangents == null);
			_vertexTangents = vertexTangents;
			invalidateBuffers(_tangentsInvalid);
		}

		/**
		 * The raw index data that define the faces.
		 *
		 * @private
		 */
		public function get indexData() : Vector.<uint>
		{
			return _indices;
		}

		/**
		 * Updates the face indices of the SubGeometry.
		 * @param indices The face indices to upload.
		 */
		public function updateIndexData(indices : Vector.<uint>) : void
		{
			_indices = indices;
			_numIndices = indices.length;

			var numTriangles : int = _numIndices/3;
			if (_numTriangles != numTriangles)
				disposeIndexBuffers(_indexBuffer);
			_numTriangles = numTriangles;
			invalidateBuffers(_indicesInvalid);
			_faceNormalsDirty = true;

			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
		}

		/**
		 * The raw data of the face normals, in the same order as the faces are listed in the index list.
		 *
		 * @private
		 */
		public function get faceNormalsData() : Vector.<Number>
		{
			if (_faceNormalsDirty) updateFaceNormals();
			return _faceNormalsData;
		}

		/**
		 * The Geometry object that 'owns' this SubGeometry object.
		 *
		 * @private
		 */
		public function get parentGeometry() : Geometry
		{
			return _parentGeometry;
		}

		public function set parentGeometry(value : Geometry) : void
		{
			_parentGeometry = value;
		}

		/**
		 * Invalidates all buffers in a vector, causing them the update when they are first requested.
		 * @param buffers The vector of buffers to invalidate.
		 */
		protected function invalidateBuffers(invalid : Vector.<Boolean>) : void
		{
			for (var i : int = 0; i < 8; ++i)
				invalid[i] = true;
		}

		/**
		 * Disposes all buffers in a given vector.
		 * @param buffers The vector of buffers to dispose.
		 */
		protected function disposeVertexBuffers(buffers : Vector.<VertexBuffer3D>) : void
		{
			for (var i : int = 0; i < 8; ++i) {
				if (buffers[i]) {
					buffers[i].dispose();
					buffers[i] = null;
				}
			}
		}

		/**
		 * Disposes all buffers in a given vector.
		 * @param buffers The vector of buffers to dispose.
		 */
		protected function disposeIndexBuffers(buffers : Vector.<IndexBuffer3D>) : void
		{
			for (var i : int = 0; i < 8; ++i) {
				if (buffers[i]) {
					buffers[i].dispose();
					buffers[i] = null;
				}
			}
		}

		/**
		 * Updates the vertex normals based on the geometry.
		 */
		private function updateVertexNormals() : void
		{
			if (_faceNormalsDirty)
				updateFaceNormals();

			var v1 : uint, v2 : uint, v3 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = _vertices.length;

			// reset, yo
			if (_vertexNormals) while (v1 < lenV) _vertexNormals[v1++] = 0.0;
			else _vertexNormals = new Vector.<Number>(_vertices.length, true);

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				index = _indices[i++]*3;
				_vertexNormals[index++] += _faceNormalsData[f1]*weight;
				_vertexNormals[index++] += _faceNormalsData[f2]*weight;
				_vertexNormals[index] += _faceNormalsData[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = 0; v2 = 1; v3 = 2;
			while (v1 < lenV) {
				var vx : Number = _vertexNormals[v1];
				var vy : Number = _vertexNormals[v2];
				var vz : Number = _vertexNormals[v3];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				_vertexNormals[v1] *= d;
				_vertexNormals[v2] *= d;
				_vertexNormals[v3] *= d;
				v1 += 3;
				v2 += 3;
				v3 += 3;
			}

			_vertexNormalsDirty = false;
			invalidateBuffers(_normalsInvalid);
		}
		
		
		private function updateDummyUVs() : void
		{
			var uvs : Vector.<Number>;
			var i : uint, idx : uint, uvIdx : uint;
			var len : uint = _vertices.length / 3 * 2;
			
			_uvs ||= new Vector.<Number>();
			_uvs.fixed = false;
			_uvs.length = 0;
			
			idx = 0;
			uvIdx = 0;
			while (idx < len) {
				if (uvIdx==0) {
					_uvs[idx++] = 0.0;
					_uvs[idx++] = 1.0;
				}
				else if (uvIdx==1) {
					_uvs[idx++] = 0.5;
					_uvs[idx++] = 0.0;
				}
				else if (uvIdx==2) {
					_uvs[idx++] = 1.0;
					_uvs[idx++] = 1.0;
				}
				
				uvIdx++;
				if (uvIdx==3)
					uvIdx = 0;
			}
			
			_uvs.fixed = true;
			
			_uvsDirty = false;
			invalidateBuffers(_uvsInvalid);
		}

		/**
		 * Updates the vertex tangents based on the geometry.
		 */
		private function updateVertexTangents() : void
		{
			if (_vertexNormalsDirty) updateVertexNormals();

			if (_faceTangentsDirty)
				updateFaceTangents();

			var v1 : uint, v2 : uint, v3 : uint;
			var f1 : uint = 0, f2 : uint = 1, f3 : uint = 2;
			var lenV : uint = _vertices.length;

			if (_vertexTangents) while (v1 < lenV) _vertexTangents[v1++] = 0.0;
			else _vertexTangents = new Vector.<Number>(_vertices.length, true);

			var i : uint, k : uint;
			var lenI : uint = _indices.length;
			var index : uint;
			var weight : uint;

			while (i < lenI) {
				weight = _useFaceWeights? _faceWeights[k++] : 1;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				index = _indices[i++]*3;
				_vertexTangents[index++] += _faceTangents[f1]*weight;
				_vertexTangents[index++] += _faceTangents[f2]*weight;
				_vertexTangents[index] += _faceTangents[f3]*weight;
				f1 += 3;
				f2 += 3;
				f3 += 3;
			}

			v1 = 0; v2 = 1; v3 = 2;
			while (v1 < lenV) {
				var vx : Number = _vertexTangents[v1];
				var vy : Number = _vertexTangents[v2];
				var vz : Number = _vertexTangents[v3];
				var d : Number = 1.0/Math.sqrt(vx*vx+vy*vy+vz*vz);
				_vertexTangents[v1] *= d;
				_vertexTangents[v2] *= d;
				_vertexTangents[v3] *= d;
				v1 += 3;
				v2 += 3;
				v3 += 3;
			}

			_vertexTangentsDirty = false;
			invalidateBuffers(_tangentsInvalid);
		}

		/**
		 * Updates the normals for each face.
		 */
		private function updateFaceNormals() : void
		{
			var i : uint, j : uint, k : uint;
			var index : uint;
			var len : uint = _indices.length;
			var x1 : Number, x2 : Number, x3 : Number;
			var y1 : Number, y2 : Number, y3 : Number;
			var z1 : Number, z2 : Number, z3 : Number;
			var dx1 : Number, dy1 : Number, dz1 : Number;
			var dx2 : Number, dy2 : Number, dz2 : Number;
			var cx : Number, cy : Number, cz : Number;
			var d : Number;

			_faceNormalsData ||= new Vector.<Number>(len, true);
			if (_useFaceWeights) _faceWeights ||= new Vector.<Number>(len/3, true);

			while (i < len) {
				index = _indices[i++]*3;
				x1 = _vertices[index++];
				y1 = _vertices[index++];
				z1 = _vertices[index];
				index = _indices[i++]*3;
				x2 = _vertices[index++];
				y2 = _vertices[index++];
				z2 = _vertices[index];
				index = _indices[i++]*3;
				x3 = _vertices[index++];
				y3 = _vertices[index++];
				z3 = _vertices[index];
				dx1 = x3-x1;
				dy1 = y3-y1;
				dz1 = z3-z1;
				dx2 = x2-x1;
				dy2 = y2-y1;
				dz2 = z2-z1;
				cx = dz1*dy2 - dy1*dz2;
				cy = dx1*dz2 - dz1*dx2;
				cz = dy1*dx2 - dx1*dy2;
				d = Math.sqrt(cx*cx+cy*cy+cz*cz);
				// length of cross product = 2*triangle area
				if (_useFaceWeights) {
					var w : Number = d*10000;
					if (w < 1) w = 1;
					_faceWeights[k++] = w;
				}
				d = 1/d;
				_faceNormalsData[j++] = cx*d;
				_faceNormalsData[j++] = cy*d;
				_faceNormalsData[j++] = cz*d;
			}

			_faceNormalsDirty = false;
			_faceTangentsDirty = true;
		}

		/**
		 * Updates the tangents for each face.
		 */
		private function updateFaceTangents() : void
		{
			var i : uint, j : uint;
			var index1 : uint, index2 : uint, index3 : uint;
			var len : uint = _indices.length;
			var ui : uint, vi : uint;
			var v0 : Number;
			var dv1 : Number, dv2 : Number;
			var denom : Number;
			var x0 : Number, y0 : Number, z0 : Number;
			var dx1 : Number, dy1 : Number, dz1 : Number;
			var dx2 : Number, dy2 : Number, dz2 : Number;
			var cx : Number, cy : Number, cz : Number;
			var invScale : Number = 1/_uvScaleV;

			_faceTangents ||= new Vector.<Number>(_indices.length, true);

			while (i < len) {
				index1 = _indices[i++];
				index2 = _indices[i++];
				index3 = _indices[i++];

				v0 = _uvs[uint((index1 << 1) + 1)];
				ui = index2 << 1;
				dv1 = (_uvs[uint((index2 << 1) + 1)] - v0)*invScale;
				ui = index3 << 1;
				dv2 = (_uvs[uint((index3 << 1) + 1)] - v0)*invScale;

				vi = index1*3;
				x0 = _vertices[vi];
				y0 = _vertices[uint(vi+1)];
				z0 = _vertices[uint(vi+2)];
				vi = index2*3;
				dx1 = _vertices[uint(vi)] - x0;
				dy1 = _vertices[uint(vi+1)] - y0;
				dz1 = _vertices[uint(vi+2)] - z0;
				vi = index3*3;
				dx2 = _vertices[uint(vi)] - x0;
				dy2 = _vertices[uint(vi+1)] - y0;
				dz2 = _vertices[uint(vi+2)] - z0;

				cx = dv2*dx1 - dv1*dx2;
				cy = dv2*dy1 - dv1*dy2;
				cz = dv2*dz1 - dv1*dz2;
				denom = 1/Math.sqrt(cx*cx + cy*cy + cz*cz);
				_faceTangents[j++] = denom*cx;
				_faceTangents[j++] = denom*cy;
				_faceTangents[j++] = denom*cz;
			}

			_faceTangentsDirty = false;
		}

		protected function disposeForStage3D(stage3DProxy : Stage3DProxy) : void
		{
			var index : int = stage3DProxy._stage3DIndex;
			if (_vertexBuffer[index]) {
				_vertexBuffer[index].dispose();
				_vertexBuffer[index] = null;
			}
			if (_uvBuffer[index]) {
				_uvBuffer[index].dispose();
				_uvBuffer[index] = null;
			}
			if (_secondaryUvBuffer[index]) {
				_secondaryUvBuffer[index].dispose();
				_secondaryUvBuffer[index] = null;
			}
			if (_vertexNormalBuffer[index]) {
				_vertexNormalBuffer[index].dispose();
				_vertexNormalBuffer[index] = null;
			}
			if (_vertexTangentBuffer[index]) {
				_vertexTangentBuffer[index].dispose();
				_vertexTangentBuffer[index] = null;
			}
			if (_indexBuffer[index]) {
				_indexBuffer[index].dispose();
				_indexBuffer[index] = null;
			}
		}

		public function get vertexStride() : uint
		{
			return 3;
		}

		public function get vertexOffset() : int
		{
			return 0;
		}

		public function get vertexNormalOffset() : int
		{
			return 0;
		}

		public function get vertexTangentOffset() : int
		{
			return 0;
		}

		public function get UVOffset() : int
		{
			return 0;
		}
	}
}