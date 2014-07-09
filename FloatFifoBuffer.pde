class FloatFifoBuffer {
  FloatBuffer _data;
  int _vector_size;
  int _wr_ptr;
  int _size;
  // initialize with data & copy 0th vector.
  FloatFifoBuffer(float[] data, int vector_size) {
    println("SIZE", data.length);
    _size = data.length;
    int _size1 = _size + vector_size; // actual capacity of the buffer
    _vector_size = vector_size;
    _wr_ptr = 0;
    _data = ByteBuffer.allocateDirect(_size1 * Float.SIZE/8).order(ByteOrder.nativeOrder()).asFloatBuffer();
    _data.rewind();
    _data.put(data);
    _data.put(data, 0, vector_size);  // repeat the 0th entries
    _data.position(0);
  }
  FloatBuffer getBuffer() {
    return _data;
  }
  void push(float[] data) {
    assert(data.length == _vector_size);
    //print("write",_wr_ptr);
    _data.position(_wr_ptr);
    _data.put(data);
    if (_wr_ptr == 0) {
      // repeat the 0th entries
      _data.position(_size);
      _data.put(data);
    }
    _wr_ptr += _vector_size;
    _wr_ptr %= _size;
    _data.position(0);
  }
  int curStartOffset() {
    int v = _wr_ptr + _vector_size; // next entry
    v %= _size;
    return v/_vector_size;
  }
};
