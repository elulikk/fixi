import type { WebSocket } from 'ws';

/** Registro de conexiones WebSocket por usuario. */
export class Hub {
  private clients = new Map<string, Set<WebSocket>>();

  add(userId: string, ws: WebSocket) {
    let set = this.clients.get(userId);
    if (!set) this.clients.set(userId, (set = new Set()));
    set.add(ws);
    ws.on('close', () => {
      set!.delete(ws);
      if (set!.size === 0) this.clients.delete(userId);
    });
  }

  send(userId: string, type: string, data: unknown) {
    const set = this.clients.get(userId);
    if (!set) return;
    const msg = JSON.stringify({ type, data });
    for (const ws of set) {
      try {
        if (ws.readyState === 1) ws.send(msg);
      } catch {
        /* conexion rota: se limpia en 'close' */
      }
    }
  }

  isOnline(userId: string) {
    return this.clients.has(userId);
  }
}
