// Draws a Lorenz system using low-level OpenGL calls.
// Adjust parameters below.  Use mouse to change camera.
//
// Copyright © 2014 Roger Allen
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
import java.nio.*;

// simultate these 2 points in a Lorenz system
float[] p  = new float[] {12.01, 12.05, 12.03, 1};
float[] p2 = new float[] {12.02, 12.06, 12.04, 1};
// Lorenz constants
final float S = 10.0, R = 28.0, B = 8.0/3;
// keep 10,000 points of history
final int N = 10000;
final int SIM_STEPS_PER_FRAME = 2;
final boolean SHOW_SECOND_POINT = true;

// global vars
PGL pgl;
PShader coloredLineShader;
Arcball arcball;
FloatFifoBuffer vertData, vertData2;
FloatFifoBuffer colorData, colorData2;

void setup() {
  size(1280, 720, P3D);
  smooth(8);
  arcball = new Arcball(width/2, height/2, 600);

  coloredLineShader = loadShader("frag.glsl", "vert.glsl");

  float[] vertices = new float[4*N];
  for (int i = 0; i < N; i++) {
    vertices[4*i+0] = 0;//100*cos((float)(2*Math.PI*i/(N)));
    vertices[4*i+1] = 0;//100*sin((float)(2*Math.PI*i/(N)));
    vertices[4*i+2] = 0;
    vertices[4*i+3] = 1;
  }
  vertData = new FloatFifoBuffer(vertices, 4);
  vertData2 = new FloatFifoBuffer(vertices, 4);

  // use a trick here.  Repeat the color gradient twice and use the 2nd
  // color gradient only.  Offset position() back from the center to
  // make it always start the colors at the center.  See draw()
  float[] colors = new float[2*4*N];
  for (int i = 0; i < 2*N; i++) { // Blue gradient
    colors[4*i+0] = 0.1 + 0.7*(i%N)/float(N-1);
    colors[4*i+1] = 0.1 + 0.7*(i%N)/float(N-1);
    colors[4*i+2] = 0.99;
    colors[4*i+3] = 1;
  }
  colorData = new FloatFifoBuffer(colors, 4);

  float[] colors2 = new float[2*4*N];
  for (int i = 0; i < 2*N; i++) { // Red gradient
    colors2[4*i+0] = 0.99;
    colors2[4*i+1] = 0.1 + 0.7*(i%N)/float(N-1);
    colors2[4*i+2] = 0.1 + 0.7*(i%N)/float(N-1);
    colors2[4*i+3] = 1;
  }
  colorData2 = new FloatFifoBuffer(colors2, 4);

}

void lorenz(float[] pt) {
  float dt = 1.0/200;
  float dx = S * (pt[1] - pt[0]) * dt;
  float dy = (pt[0] * (R - pt[2]) - pt[1]) * dt;
  float dz = (pt[0] * pt[1] - B * pt[2]) * dt;
  pt[0] += dx;
  pt[1] += dy;
  pt[2] += dz;
}

void drawColoredLine(FloatFifoBuffer vData, FloatFifoBuffer cData) {
  coloredLineShader.bind();

  int vertLoc = pgl.getAttribLocation(coloredLineShader.glProgram, "vertex");
  int colorLoc = pgl.getAttribLocation(coloredLineShader.glProgram, "color");

  pgl.enableVertexAttribArray(vertLoc);
  pgl.enableVertexAttribArray(colorLoc);

  int K = vData.curStartOffset();
  // trick: offset K will read color data from start of gradient
  cData.getBuffer().position(N*4-K*4);
  pgl.vertexAttribPointer(vertLoc, 4, PGL.FLOAT, false, 0, vData.getBuffer());
  pgl.vertexAttribPointer(colorLoc, 4, PGL.FLOAT, false, 0, cData.getBuffer());
  if (K==0) {
    pgl.drawArrays(PGL.LINE_STRIP, 0, N-1);
  } else {
    pgl.drawArrays(PGL.LINE_STRIP, K, N-K+1);
    pgl.drawArrays(PGL.LINE_STRIP, 0, K-1);
  }

  pgl.disableVertexAttribArray(vertLoc);
  pgl.disableVertexAttribArray(colorLoc);

  coloredLineShader.unbind();
}

void draw() {
  background(0);

  translate(width/2 + 10, height/2 - 10 , 10);
  scale(9.0);
  arcball.run();

  for(int i = 0; i < SIM_STEPS_PER_FRAME; i++) {
    lorenz(p);
    lorenz(p2);
    vertData.push(p);
    vertData2.push(p2);
  }

  pgl = beginPGL();

  drawColoredLine(vertData, colorData);
  if(SHOW_SECOND_POINT) {
    drawColoredLine(vertData2, colorData2);
  }

  endPGL();
}

void mousePressed(){
  arcball.mousePressed();
}

void mouseDragged(){
  arcball.mouseDragged();
}
