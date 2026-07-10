// 撤销/重做管理器(占位 — 未来可接入完整快照)
export class UndoManager {
  private undoStack: string[] = [];
  private redoStack: string[] = [];
  private maxSteps: number = 30;

  commit(snapshot: string): void {
    this.undoStack.push(snapshot);
    this.redoStack = [];
    if (this.undoStack.length > this.maxSteps) {
      this.undoStack.splice(0, 1);
    }
  }

  undo(): string | undefined {
    if (this.undoStack.length === 0) return undefined;
    const current: string | undefined = this.undoStack.pop();
    if (current !== undefined) {
      this.redoStack.push(current);
    }
    if (this.undoStack.length > 0) {
      return this.undoStack[this.undoStack.length - 1];
    }
    return undefined;
  }

  redo(): string | undefined {
    if (this.redoStack.length === 0) return undefined;
    const next: string | undefined = this.redoStack.pop();
    if (next !== undefined) {
      this.undoStack.push(next);
    }
    return next;
  }

  clear(): void {
    this.undoStack = [];
    this.redoStack = [];
  }
}
