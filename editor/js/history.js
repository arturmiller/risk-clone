// editor/js/history.js
export class UndoStack {
  constructor(maxSize = 100) {
    this.stack = [];
    this.index = -1;
    this.maxSize = maxSize;
  }

  push(graphClone, territoriesClone) {
    this.stack.length = this.index + 1;
    this.stack.push({ graph: graphClone, territories: territoriesClone });
    if (this.stack.length > this.maxSize) {
      this.stack.shift();
    }
    this.index = this.stack.length - 1;
  }

  canUndo() { return this.index > 0; }
  canRedo() { return this.index < this.stack.length - 1; }

  undo() {
    if (!this.canUndo()) return null;
    this.index--;
    return this.stack[this.index];
  }

  redo() {
    if (!this.canRedo()) return null;
    this.index++;
    return this.stack[this.index];
  }
}
