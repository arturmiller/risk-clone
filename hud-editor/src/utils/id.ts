let counter = 0;

export function generateId(prefix: string = 'el'): string {
  counter++;
  return `${prefix}-${counter}-${Date.now().toString(36)}`;
}

export function resetIdCounter(): void {
  counter = 0;
}
