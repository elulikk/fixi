import bcrypt from 'bcryptjs';
import type { Config } from './config.js';
import type { Db } from './db.js';
import { commissionOf, levelFor, newId } from './util.js';

export const DEMO_PASSWORD = 'fixi1234';

const CATEGORIES: [string, string, string, string][] = [
  ['pc-notebooks', 'PC y notebooks', 'laptop_mac', 'Tecnología'],
  ['celulares-tablets', 'Celulares y tablets', 'smartphone', 'Tecnología'],
  ['redes-wifi', 'Redes y WiFi', 'wifi', 'Tecnología'],
  ['consolas', 'Consolas', 'sports_esports', 'Tecnología'],
  ['impresoras', 'Impresoras', 'print', 'Tecnología'],
  ['heladeras', 'Heladeras', 'kitchen', 'Electrodomésticos'],
  ['lavarropas', 'Lavarropas', 'local_laundry_service', 'Electrodomésticos'],
  ['aire-acondicionado', 'Aire acondicionado', 'ac_unit', 'Electrodomésticos'],
  ['tv-audio', 'TV y audio', 'tv', 'Electrodomésticos'],
  ['cocinas-hornos', 'Cocinas y hornos', 'microwave', 'Electrodomésticos'],
  ['electricista', 'Electricista', 'bolt', 'Hogar'],
  ['plomero', 'Plomero', 'plumbing', 'Hogar'],
  ['gasista', 'Gasista', 'local_fire_department', 'Hogar'],
  ['cerrajero', 'Cerrajero', 'key', 'Hogar'],
  ['pintor', 'Pintor', 'format_paint', 'Hogar'],
  ['albanil', 'Albañil', 'construction', 'Hogar'],
  ['otros', 'Otros', 'build', 'Otros'],
];

interface TechSeed {
  k: string; name: string; email: string; phone: string; lat: number; lng: number; addr: string; cats: string[];
  radius: number; bio: string; rating: number; count: number; jobs: number; points: number; verified: boolean; available?: boolean;
}
const TECHS: TechSeed[] = [
  { k: 'diego', name: 'Diego Fernández', email: 'tecnico@fixi.app', phone: '+54 11 5555-0101', lat: -34.6093, lng: -58.4207, addr: 'Almagro, CABA', cats: ['pc-notebooks', 'redes-wifi'], radius: 15, bio: 'Técnico en informática con 12 años de experiencia. Reparación de notebooks y PCs, instalación de redes y WiFi mesh. El diagnóstico va sin cargo si hacemos la reparación.', rating: 4.8, count: 86, jobs: 94, points: 780, verified: true },
  { k: 'lucas', name: 'Lucas Pereyra', email: 'lucas.pereyra@fixi.demo', phone: '+54 11 5555-0102', lat: -34.6088, lng: -58.4064, addr: 'Once, CABA', cats: ['celulares-tablets', 'pc-notebooks'], radius: 12, bio: 'Reparo celulares y tablets al instante: pantallas, baterías y pines de carga. Repuestos de calidad y garantía escrita de 3 meses.', rating: 4.6, count: 41, jobs: 47, points: 340, verified: true },
  { k: 'gustavo', name: 'Gustavo Molina', email: 'gustavo.molina@fixi.demo', phone: '+54 11 5555-0103', lat: -34.6256, lng: -58.4189, addr: 'Boedo, CABA', cats: ['heladeras', 'lavarropas', 'aire-acondicionado'], radius: 18, bio: '25 años en service de línea blanca. Heladeras no frost, lavarropas automáticos y aires split. Voy con repuestos en la camioneta, casi siempre lo resuelvo en la primera visita.', rating: 4.9, count: 132, jobs: 158, points: 1720, verified: true },
  { k: 'romina', name: 'Romina Salvatierra', email: 'romina.salvatierra@fixi.demo', phone: '+54 11 5555-0104', lat: -34.5993, lng: -58.438, addr: 'Villa Crespo, CABA', cats: ['electricista'], radius: 14, bio: 'Electricista matriculada. Tableros, cableado, luminarias y urgencias. Trabajo prolijo y entrego certificado de instalación.', rating: 4.7, count: 63, jobs: 71, points: 690, verified: true },
  { k: 'nico', name: 'Nicolás Aguirre', email: 'nicolas.aguirre@fixi.demo', phone: '+54 11 5555-0105', lat: -34.6445, lng: -58.3694, addr: 'Barracas, CABA', cats: ['plomero', 'gasista'], radius: 15, bio: 'Plomería y gas matriculado. Destapaciones, pérdidas, termotanques y calefones. Presupuesto en el momento.', rating: 4.5, count: 38, jobs: 44, points: 410, verified: true },
  { k: 'hernan', name: 'Hernán Cabrera', email: 'hernan.cabrera@fixi.demo', phone: '+54 11 5555-0106', lat: -34.6118, lng: -58.379, addr: 'Monserrat, CABA', cats: ['aire-acondicionado'], radius: 20, bio: 'Instalación y mantenimiento de splits. Carga de gas, limpieza de equipos y service preventivo antes del verano.', rating: 4.2, count: 9, jobs: 11, points: 95, verified: false },
  { k: 'ariel', name: 'Ariel Sosa', email: 'ariel.sosa@fixi.demo', phone: '+54 11 5555-0107', lat: -34.5875, lng: -58.3974, addr: 'Recoleta, CABA', cats: ['tv-audio', 'consolas'], radius: 12, bio: 'Smart TVs, home theaters y consolas. Cambio de pantallas, fuentes y puertos HDMI. También instalo soportes y configuro todo.', rating: 4.6, count: 52, jobs: 58, points: 520, verified: true },
  { k: 'mariano', name: 'Mariano Quiroga', email: 'mariano.quiroga@fixi.demo', phone: '+54 11 5555-0108', lat: -34.6272, lng: -58.3813, addr: 'Constitución, CABA', cats: ['cerrajero'], radius: 20, bio: 'Cerrajería 24 hs. Apertura de puertas sin romper, cambio de bombines y copias de llaves. Llego rápido.', rating: 4.8, count: 97, jobs: 112, points: 1010, verified: true },
  { k: 'fede', name: 'Federico Luna', email: 'federico.luna@fixi.demo', phone: '+54 11 5555-0109', lat: -34.628, lng: -58.464, addr: 'Flores, CABA', cats: ['pintor', 'albanil'], radius: 12, bio: 'Pintura de interiores y exteriores, revoques y arreglos de albañilería. Presupuesto sin cargo. Recién empiezo en Fixi.', rating: 0, count: 0, jobs: 0, points: 0, verified: false, available: false },
  { k: 'paula', name: 'Paula Domínguez', email: 'paula.dominguez@fixi.demo', phone: '+54 11 5555-0110', lat: -34.545, lng: -58.456, addr: 'Núñez, CABA', cats: ['electricista', 'cocinas-hornos'], radius: 15, bio: 'Electricista y service de cocinas y hornos eléctricos. Atiendo zona Norte de CABA y Vicente López.', rating: 4.4, count: 27, jobs: 31, points: 260, verified: true },
  { k: 'cristian', name: 'Cristian Barrios', email: 'cristian.barrios@fixi.demo', phone: '+54 11 5555-0111', lat: -34.662, lng: -58.365, addr: 'Avellaneda, GBA', cats: ['pc-notebooks', 'impresoras', 'redes-wifi'], radius: 15, bio: 'Armado y reparación de PCs, formateos, upgrade de SSD/RAM y service de impresoras. Atiendo Avellaneda, Lanús y CABA sur.', rating: 4.3, count: 18, jobs: 21, points: 150, verified: false },
  { k: 'walter', name: 'Walter Giménez', email: 'walter.gimenez@fixi.demo', phone: '+54 11 5555-0112', lat: -34.7058, lng: -58.3918, addr: 'Lanús, GBA', cats: ['gasista', 'plomero', 'aire-acondicionado', 'cocinas-hornos'], radius: 25, bio: 'Gasista matriculado con 18 años en zona Sur. Instalación de cocinas, calefones y estufas, y carga de gas de aires acondicionados.', rating: 4.7, count: 70, jobs: 83, points: 880, verified: true },
];

interface ClientSeed { k: string; name: string; email: string; phone: string; lat: number; lng: number; addr: string }
const CLIENTS: ClientSeed[] = [
  { k: 'martina', name: 'Martina Gómez', email: 'cliente@fixi.app', phone: '+54 11 6000-0001', lat: -34.5875, lng: -58.43, addr: 'Gorriti 4820, Palermo' },
  { k: 'julian', name: 'Julián Ríos', email: 'julian.rios@fixi.demo', phone: '+54 11 6000-0002', lat: -34.6186, lng: -58.444, addr: 'Av. Rivadavia 5200, Caballito' },
  { k: 'carolina', name: 'Carolina Benítez', email: 'carolina.benitez@fixi.demo', phone: '+54 11 6000-0003', lat: -34.5627, lng: -58.4564, addr: 'Cabildo 2300, Belgrano' },
  { k: 'seba', name: 'Sebastián Acosta', email: 'sebastian.acosta@fixi.demo', phone: '+54 11 6000-0004', lat: -34.6217, lng: -58.3731, addr: 'Defensa 1050, San Telmo' },
];

// [tech, categoria, titulo, descripcion, precio ARS, tipo, minutos]
type L = [string, string, string, string, number, 'fixed' | 'from' | 'hourly', number];
const LISTINGS: L[] = [
  ['diego', 'pc-notebooks', 'Diagnóstico y reparación de notebook', 'Revisión completa, limpieza interna y cambio de pasta térmica. Si hay que reemplazar un repuesto se presupuesta aparte.', 38000, 'from', 90],
  ['diego', 'pc-notebooks', 'Formateo + instalación de Windows y programas', 'Backup de tus archivos, instalación limpia, drivers y antivirus.', 32000, 'fixed', 120],
  ['diego', 'redes-wifi', 'Configuración de WiFi mesh en tu casa', 'Instalación y optimización de router o mesh para eliminar zonas sin señal.', 45000, 'fixed', 90],
  ['lucas', 'celulares-tablets', 'Cambio de pantalla de celular', 'Pantallas para Samsung, Motorola, Xiaomi e iPhone. Garantía de 3 meses.', 85000, 'from', 60],
  ['lucas', 'celulares-tablets', 'Cambio de batería', 'Batería nueva con prueba de ciclos. En el día.', 48000, 'fixed', 45],
  ['lucas', 'pc-notebooks', 'Limpieza de virus y recuperación de datos', 'Eliminación de malware y rescate de archivos de discos con fallas.', 40000, 'fixed', 90],
  ['gustavo', 'heladeras', 'Reparación de heladera (no enfría)', 'Diagnóstico y reparación en domicilio. Carga de gas y cambio de termostato.', 65000, 'from', 120],
  ['gustavo', 'lavarropas', 'Service de lavarropas automático', 'Cambio de correa, rulemanes y bomba de desagote.', 58000, 'from', 120],
  ['gustavo', 'aire-acondicionado', 'Instalación de aire acondicionado split', 'Instalación estándar hasta 3 m de cañería, soporte y puesta en marcha.', 185000, 'fixed', 240],
  ['hernan', 'aire-acondicionado', 'Limpieza y mantenimiento de split', 'Limpieza de filtros, turbina y unidad exterior. Revisión de gas.', 42000, 'fixed', 75],
  ['hernan', 'aire-acondicionado', 'Carga de gas refrigerante', 'Detección de fugas y recarga con gas R410A.', 70000, 'from', 90],
  ['romina', 'electricista', 'Instalación de punto de luz o tomacorriente', 'Incluye mano de obra y materiales menores.', 28000, 'fixed', 60],
  ['romina', 'electricista', 'Revisión de tablero y térmicas', 'Diagnóstico de cortes de luz, cambio de térmicas y disyuntor.', 55000, 'from', 90],
  ['romina', 'electricista', 'Electricista de urgencias (por hora)', 'Atención el mismo día. Valor por hora de trabajo.', 22000, 'hourly', 60],
  ['nico', 'plomero', 'Destapación de cañerías y bachas', 'Con máquina eléctrica. Garantía de 30 días.', 52000, 'from', 90],
  ['nico', 'gasista', 'Cambio de calefón o termotanque', 'Retiro del equipo viejo e instalación. El equipo no está incluido.', 98000, 'fixed', 150],
  ['ariel', 'tv-audio', 'Reparación de Smart TV', 'Fuentes, backlight, placas y software.', 60000, 'from', 120],
  ['ariel', 'tv-audio', 'Instalación de TV en pared + configuración', 'Soporte, nivelación y ocultamiento de cables.', 36000, 'fixed', 60],
  ['ariel', 'consolas', 'Service de PS5 / Xbox: limpieza y HDMI', 'Cambio de pasta térmica, limpieza y reparación de puerto HDMI.', 75000, 'from', 120],
  ['mariano', 'cerrajero', 'Apertura de puerta sin romper', 'Atención 24 hs. Llego en menos de 40 minutos.', 45000, 'fixed', 45],
  ['mariano', 'cerrajero', 'Cambio de bombín de seguridad', 'Bombín antibumping con 5 llaves.', 62000, 'fixed', 60],
  ['fede', 'pintor', 'Pintura de ambiente (hasta 15 m²)', 'Dos manos, incluye pintura y protección de muebles.', 150000, 'from', 480],
  ['paula', 'electricista', 'Instalación de ventilador de techo', 'Incluye armado, fijación y conexión.', 32000, 'fixed', 75],
  ['paula', 'cocinas-hornos', 'Service de horno eléctrico y anafe', 'Cambio de resistencias, termostatos y perillas.', 48000, 'from', 90],
  ['cristian', 'pc-notebooks', 'Armado de PC gamer / oficina', 'Armado, cableado prolijo, instalación y pruebas de estrés.', 40000, 'fixed', 150],
  ['cristian', 'impresoras', 'Service de impresora (cabezal y limpieza)', 'Limpieza profunda de cabezales y cambio de rodillos. Epson, HP y Brother.', 35000, 'from', 75],
  ['cristian', 'pc-notebooks', 'Upgrade a SSD + ampliación de RAM', 'Clonado del disco actual, cambio a SSD y más memoria.', 30000, 'fixed', 60],
  ['walter', 'gasista', 'Instalación de cocina a gas con prueba de hermeticidad', 'Incluye flexible y certificado de la prueba.', 65000, 'fixed', 90],
  ['walter', 'cocinas-hornos', 'Reparación de cocina u horno a gas', 'Cambio de termocuplas, válvulas y quemadores.', 50000, 'from', 90],
  ['walter', 'aire-acondicionado', 'Instalación de split zona Sur', 'Instalación completa con cañería hasta 3 m.', 170000, 'fixed', 240],
];

function mulberry32(a: number) {
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function seedDatabase(db: Db, cfg: Pick<Config, 'commissionPercent' | 'port' | 'publicBaseUrl'>) {
  const rnd = mulberry32(2026);
  const pick = <T>(a: T[]): T => a[Math.floor(rnd() * a.length)];
  const hash = bcrypt.hashSync(DEMO_PASSWORD, 10);
  const at = (daysAgo: number, plusMin = 0) => new Date(Date.now() - daysAgo * 864e5 + plusMin * 60000).toISOString();
  const base = cfg.publicBaseUrl || `http://localhost:${cfg.port}`;

  db.tx(() => {
    // ---- Categorias ----
    CATEGORIES.forEach(([slug, name, icon, grp], i) =>
      db.run('INSERT INTO categories (id, slug, name, icon, grp, sort_order) VALUES (?,?,?,?,?,?)', `c_${slug}`, slug, name, icon, grp, i),
    );
    const cat = (slug: string) => `c_${slug}`;

    // ---- Usuarios ----
    const uid: Record<string, string> = {};
    const addUser = (k: string, name: string, email: string, phone: string, lat: number | null, lng: number | null, addr: string | null, role: string, isTech: boolean, daysAgo: number) => {
      const id = newId();
      uid[k] = id;
      db.run(
        `INSERT INTO users (id, name, email, phone, avatar_url, role, is_technician, lat, lng, address, password_hash, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`,
        id, name, email, phone, `https://i.pravatar.cc/300?u=${id}`, role, isTech, lat, lng, addr, hash, at(daysAgo),
      );
    };
    addUser('admin', 'Admin Fixi', 'admin@fixi.app', '+54 11 4000-0000', -34.6037, -58.3816, 'Obelisco, CABA', 'admin', false, 90);
    CLIENTS.forEach((c, i) => addUser(c.k, c.name, c.email, c.phone, c.lat, c.lng, c.addr, 'user', false, 60 - i * 7));
    TECHS.forEach((t, i) => {
      addUser(t.k, t.name, t.email, t.phone, t.lat, t.lng, t.addr, 'user', true, 80 - i * 5);
      db.run(
        `INSERT INTO tech_profiles (user_id, bio, category_ids, radius_km, available, verified, rating_avg, rating_count, jobs_done, points, level, payments_connected)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,1)`,
        uid[t.k], t.bio, JSON.stringify(t.cats.map(cat)), t.radius, t.available ?? true, t.verified, t.rating, t.count, t.jobs, t.points, levelFor(t.points),
      );
    });
    // La cuenta demo de tecnico tambien puede actuar como cliente; Martina (cliente demo) queda solo cliente.

    // ---- Servicios publicados ----
    const lid: Record<string, string> = {};
    LISTINGS.forEach(([tk, cs, title, desc, price, ptype, dur], i) => {
      const id = newId();
      lid[title] = id;
      db.run(
        `INSERT INTO listings (id, tech_id, category_id, title, description, price, price_type, duration_minutes, active, created_at) VALUES (?,?,?,?,?,?,?,?,1,?)`,
        id, uid[tk], cat(cs), title, desc, price, ptype, dur, at(40 - (i % 30)),
      );
    });
    const listing = (title: string) => lid[title];
    const listingRow = (title: string) => db.get('SELECT * FROM listings WHERE id = ?', lid[title])!;

    // ---- Necesidades abiertas con ofertas ----
    const addRequest = (client: string, cs: string, title: string, desc: string, budget: number | null, urgency: string, status: string, daysAgo: number, scheduledInDays?: number) => {
      const c = CLIENTS.find((x) => x.k === client)!;
      const id = newId();
      db.run(
        `INSERT INTO requests (id, client_id, category_id, title, description, photos, lat, lng, address, budget_max, urgency, scheduled_at, status, offers_count, created_at)
         VALUES (?,?,?,?,?, '[]', ?,?,?,?,?,?,?, 0, ?)`,
        id, uid[client], cat(cs), title, desc, c.lat, c.lng, c.addr, budget, urgency,
        scheduledInDays ? at(-scheduledInDays) : null, status, at(daysAgo),
      );
      return id;
    };
    const addOffer = (reqId: string, tech: string, price: number, eta: number, dur: number, message: string, status = 'pending', daysAgo = 0.1) => {
      const id = newId();
      db.run(
        `INSERT INTO offers (id, request_id, tech_id, price, eta_minutes, duration_minutes, message, status, created_at) VALUES (?,?,?,?,?,?,?,?,?)`,
        id, reqId, uid[tech], price, eta, dur, message, status, at(daysAgo),
      );
      db.run('UPDATE requests SET offers_count = offers_count + 1 WHERE id = ?', reqId);
      return id;
    };

    const r1 = addRequest('martina', 'pc-notebooks', 'Mi notebook no enciende', 'Una Lenovo IdeaPad de 3 años. Dejó de prender de un día para otro, el led de carga parpadea pero no pasa de ahí.', 60000, 'today', 'open', 0.2);
    addOffer(r1, 'diego', 46000, 35, 90, 'Puede ser la fuente o la placa. Voy con repuestos y te cuento en el momento qué tiene.');
    addOffer(r1, 'cristian', 39000, 70, 120, 'Te lo reviso en tu casa y, si hace falta, me lo llevo al taller sin cargo extra.');
    addOffer(r1, 'lucas', 52000, 25, 80, 'Estoy cerca de tu zona, en media hora puedo estar. Diagnóstico incluido.');

    const r2 = addRequest('julian', 'aire-acondicionado', 'El aire split no enfría', 'Es un split de 3000 frigorías, de 5 años. Prende y sopla pero sale aire común. Antes de que llegue el calor quiero dejarlo andando.', 80000, 'now', 'open', 0.1);
    addOffer(r2, 'gustavo', 68000, 50, 90, 'Seguramente es falta de gas o el capacitor. Llevo todo para resolverlo en el día.');
    addOffer(r2, 'hernan', 55000, 30, 75, 'Estoy en Monserrat, puedo salir ya mismo. Limpieza de filtros incluida.');
    addOffer(r2, 'walter', 72000, 65, 90, 'Hago la carga de gas con detección de fugas y te dejo garantía por escrito.');

    const r3 = addRequest('carolina', 'plomero', 'Pérdida de agua debajo de la bacha de la cocina', 'Gotea desde el sifón y ya se hinchó el mueble. Necesito que lo vean pronto.', 50000, 'today', 'open', 0.3);
    addOffer(r3, 'nico', 45000, 40, 60, 'Cambio de sifón y flexibles. Llevo los repuestos comunes.');
    addOffer(r3, 'walter', 50000, 55, 75, 'Puedo ir hoy a la tarde. Reviso toda la instalación de la cocina.');

    const r4 = addRequest('seba', 'electricista', 'Salta la térmica cada vez que uso el horno', 'Es un horno eléctrico. Cuando lo prendo junto con la heladera salta la térmica de la cocina.', 40000, 'scheduled', 'open', 0.5, 2);
    addOffer(r4, 'romina', 38000, 60, 60, 'Puede ser la sección del cable o una térmica subdimensionada. Lo medimos y lo resolvemos.');
    addOffer(r4, 'paula', 42000, 90, 75, 'Reviso tablero y línea de cocina, con certificado de la instalación.');

    const r5 = addRequest('martina', 'heladeras', 'La heladera hace ruido y no enfría', 'Heladera no frost de 8 años. El freezer enfría pero abajo no.', null, 'today', 'open', 0.6);
    addOffer(r5, 'gustavo', 62000, 70, 100, 'Es típico del evaporador o el ventilador. Lo reviso y lo arreglo en la misma visita.');

    const r6 = addRequest('julian', 'cerrajero', 'Cerradura trabada, no puedo entrar al departamento', 'La llave gira pero no abre. Estoy esperando en el palier.', 55000, 'now', 'open', 0.05);
    addOffer(r6, 'mariano', 48000, 20, 40, 'Estoy a 15 minutos. Abro sin romper la cerradura.');

    addRequest('carolina', 'tv-audio', 'Smart TV sin imagen pero con sonido', 'Una TV de 50 pulgadas, se escucha pero la pantalla queda negra.', 70000, 'today', 'open', 0.15);

    // ---- Trabajos ----
    const PAID = ['paid', 'on_the_way', 'in_progress', 'done', 'completed', 'disputed'];
    const HELD = ['paid', 'on_the_way', 'in_progress', 'done', 'disputed'];
    interface J { client: string; tech: string; cs: string; title: string; price: number; status: string; daysAgo: number; eta?: number; listingId?: string; requestId?: string; offerId?: string; address?: string; refunded?: boolean; late?: boolean }
    const mkJob = (o: J) => {
      const c = CLIENTS.find((x) => x.k === o.client)!;
      const id = newId();
      const eta = o.eta ?? 30;
      const commission = commissionOf(o.price, cfg.commissionPercent);
      const paymentStatus = o.status === 'completed' ? 'released' : HELD.includes(o.status) ? 'held' : o.refunded ? 'refunded' : 'pending';
      const paid = PAID.includes(o.status) || o.refunded;
      const started = ['in_progress', 'done', 'completed', 'disputed'].includes(o.status);
      const onTheWay = started || o.status === 'on_the_way';
      db.run(
        `INSERT INTO jobs (id, request_id, offer_id, listing_id, client_id, tech_id, category_id, title, address, lat, lng, price, commission, tech_net, eta_minutes,
           status, payment_status, on_the_way_at, on_time, created_at, paid_at, started_at, completed_at)
         VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
        id, o.requestId ?? null, o.offerId ?? null, o.listingId ?? null, uid[o.client], uid[o.tech], cat(o.cs), o.title, o.address ?? c.addr, c.lat, c.lng,
        o.price, commission, o.price - commission, eta, o.status, paymentStatus,
        onTheWay ? at(o.daysAgo, 20) : null, o.late ? 0 : 1, at(o.daysAgo), paid ? at(o.daysAgo, 8) : null,
        started ? at(o.daysAgo, 20 + eta - (o.late ? -10 : 5)) : null, o.status === 'completed' ? at(o.daysAgo, 200) : null,
      );
      const pid = newId();
      const pstatus = o.status === 'completed' ? 'released' : HELD.includes(o.status) ? 'approved' : o.refunded ? 'refunded' : o.status === 'cancelled' ? 'failed' : 'pending';
      db.run(
        `INSERT INTO payments (id, job_id, provider, provider_ref, amount, commission, status, checkout_url, created_at) VALUES (?,?,?,?,?,?,?,?,?)`,
        pid, id, 'mock', `MOCK-${pid.slice(0, 8)}`, o.price, commission, pstatus, `${base}/pay/mock/${pid}`, at(o.daysAgo, 5),
      );
      return id;
    };
    const review = (jobId: string, from: string, to: string, rating: number, comment: string, daysAgo: number) =>
      db.run('INSERT INTO reviews (id, job_id, from_user_id, to_user_id, rating, comment, created_at) VALUES (?,?,?,?,?,?,?)', newId(), jobId, uid[from], uid[to], rating, comment, at(daysAgo, 260));
    const msg = (jobId: string, from: string, text: string, daysAgo: number, plusMin: number) =>
      db.run('INSERT INTO messages (id, job_id, from_user_id, text, created_at) VALUES (?,?,?,?,?)', newId(), jobId, uid[from], text, at(daysAgo, plusMin));

    // J1: completado con reseñas (cliente demo <-> tecnico demo)
    const j1 = mkJob({ client: 'martina', tech: 'diego', cs: 'pc-notebooks', title: 'Formateo + instalación de Windows y programas', price: 32000, status: 'completed', daysAgo: 12, eta: 35, listingId: listing('Formateo + instalación de Windows y programas') });
    review(j1, 'martina', 'diego', 5, 'Excelente atención. Dejó la notebook como nueva y me explicó todo. Súper recomendable.', 12);
    review(j1, 'diego', 'martina', 5, 'Clienta muy amable y puntual.', 12);

    // J2: completado desde una necesidad
    const r7 = addRequest('julian', 'electricista', 'Cambiar tablero y térmicas', 'El tablero es viejo, con fusibles. Quiero pasar a térmicas y disyuntor.', 60000, 'scheduled', 'closed', 9);
    const o7a = addOffer(r7, 'romina', 55000, 45, 120, 'Hago el cambio completo con certificado.', 'accepted', 9);
    addOffer(r7, 'paula', 59000, 80, 120, 'Puedo ir el jueves a la mañana.', 'rejected', 9);
    const j2 = mkJob({ client: 'julian', tech: 'romina', cs: 'electricista', title: 'Cambiar tablero y térmicas', price: 55000, status: 'completed', daysAgo: 8, eta: 45, requestId: r7, offerId: o7a });
    review(j2, 'julian', 'romina', 5, 'Romina es una genia: prolija, rápida y me dejó el certificado. Volvería a contratarla.', 8);
    review(j2, 'romina', 'julian', 4, 'Todo bien, nos coordinamos por el chat sin problemas.', 8);

    // J3: completado, 4 estrellas
    const j3 = mkJob({ client: 'carolina', tech: 'gustavo', cs: 'heladeras', title: 'Reparación de heladera (no enfría)', price: 65000, status: 'completed', daysAgo: 5, eta: 60, listingId: listing('Reparación de heladera (no enfría)'), late: true });
    review(j3, 'carolina', 'gustavo', 4, 'Muy buen trabajo, la heladera quedó andando. Solo llegó 15 minutos tarde.', 5);

    // Estados intermedios
    const j4 = mkJob({ client: 'seba', tech: 'hernan', cs: 'aire-acondicionado', title: 'Limpieza y mantenimiento de split', price: 42000, status: 'in_progress', daysAgo: 0.15, eta: 25, listingId: listing('Limpieza y mantenimiento de split') });
    msg(j4, 'hernan', 'Hola Sebastián, ya llegué. Toco el timbre del 4°B.', 0.1, 0);
    msg(j4, 'seba', 'Perfecto, bajo a abrirte.', 0.1, 1);
    msg(j4, 'hernan', 'Tengo para una hora de trabajo aproximadamente.', 0.1, 6);

    const j5 = mkJob({ client: 'martina', tech: 'lucas', cs: 'celulares-tablets', title: 'Cambio de batería', price: 48000, status: 'on_the_way', daysAgo: 0.05, eta: 20, listingId: listing('Cambio de batería') });
    msg(j5, 'martina', 'Hola Lucas, es un Samsung A52. ¿Tenés la batería disponible?', 0.04, 0);
    msg(j5, 'lucas', '¡Hola Martina! Sí, la llevo conmigo. Estoy llegando en 15 minutos.', 0.04, 2);

    mkJob({ client: 'julian', tech: 'ariel', cs: 'tv-audio', title: 'Instalación de TV en pared + configuración', price: 36000, status: 'paid', daysAgo: 0.1, eta: 40, listingId: listing('Instalación de TV en pared + configuración') });

    const r8 = addRequest('carolina', 'pc-notebooks', 'Pantalla rota de notebook', 'Se me cayó y la pantalla quedó con rayas. Es una HP de 15 pulgadas.', 70000, 'today', 'assigned', 0.4);
    const o8 = addOffer(r8, 'cristian', 62000, 60, 120, 'Consigo la pantalla y te la cambio en una visita.', 'accepted', 0.35);
    mkJob({ client: 'carolina', tech: 'cristian', cs: 'pc-notebooks', title: 'Pantalla rota de notebook', price: 62000, status: 'pending_payment', daysAgo: 0.02, eta: 60, requestId: r8, offerId: o8 });

    const j8 = mkJob({ client: 'seba', tech: 'mariano', cs: 'cerrajero', title: 'Cambio de bombín de seguridad', price: 62000, status: 'done', daysAgo: 0.3, eta: 30, listingId: listing('Cambio de bombín de seguridad') });
    msg(j8, 'mariano', 'Listo Sebastián, te dejé las 5 llaves y la tarjeta de garantía.', 0.2, 0);
    msg(j8, 'seba', 'Gracias Mariano, ya lo confirmo en la app.', 0.2, 3);

    const j9 = mkJob({ client: 'martina', tech: 'walter', cs: 'gasista', title: 'Instalación de cocina a gas con prueba de hermeticidad', price: 65000, status: 'disputed', daysAgo: 3, eta: 50, listingId: listing('Instalación de cocina a gas con prueba de hermeticidad') });
    msg(j9, 'martina', 'Walter, la llama de la hornalla trasera sale amarilla y huele a gas.', 2.9, 0);
    msg(j9, 'walter', 'Eso no puede ser, la prueba dio bien. Mañana paso a revisarlo.', 2.9, 15);
    msg(j9, 'martina', 'No pasaste y sigue igual. Voy a abrir un reclamo.', 2, 0);

    mkJob({ client: 'julian', tech: 'paula', cs: 'electricista', title: 'Instalación de ventilador de techo', price: 32000, status: 'cancelled', daysAgo: 6, eta: 40, listingId: listing('Instalación de ventilador de techo') });

    // ---- Historial de los ultimos 30 dias (para estadisticas y ganancias) ----
    const comments = [
      [5, 'Todo perfecto, rápido y muy prolijo.'], [5, 'Excelente servicio, 100% recomendable.'], [4, 'Buen trabajo, el precio fue justo.'],
      [5, 'Muy amable y profesional. Resolvió todo en una visita.'], [4, 'Cumplió con lo pactado. Volvería a contratarlo.'], [3, 'Hizo el trabajo pero tardó más de lo esperado.'],
    ] as const;
    const clientKeys = CLIENTS.map((c) => c.k);
    for (let i = 0; i < 20; i++) {
      const l = pick(LISTINGS.filter((x) => x[0] !== 'fede'));
      const ck = pick(clientKeys);
      const jid = mkJob({ client: ck, tech: l[0], cs: l[1], title: l[2], price: l[4], status: 'completed', daysAgo: 1 + Math.floor(rnd() * 29), eta: 20 + Math.floor(rnd() * 40), listingId: lid[l[2]] });
      if (rnd() < 0.55) {
        const [r, t] = pick(comments as unknown as [number, string][]);
        review(jid, ck, l[0], r, t, 1);
      }
    }
    // Un par de pagos en curso mas, para que el panel muestre movimiento hoy
    void listingRow;

    // ---- Notificaciones de demo ----
    const notif = (user: string, type: string, title: string, body: string, data: object, read: boolean, daysAgo: number) =>
      db.run('INSERT INTO notifications (id, user_id, type, title, body, data, read, created_at) VALUES (?,?,?,?,?,?,?,?)', newId(), uid[user], type, title, body, JSON.stringify(data), read, at(daysAgo));
    notif('martina', 'offer.new', 'Nueva oferta', 'Lucas Pereyra ofertó $52.000 por "Mi notebook no enciende".', { requestId: r1 }, false, 0.05);
    notif('martina', 'offer.new', 'Nueva oferta', 'Cristian Barrios ofertó $39.000 por "Mi notebook no enciende".', { requestId: r1 }, false, 0.1);
    notif('martina', 'offer.new', 'Nueva oferta', 'Diego Fernández ofertó $46.000 por "Mi notebook no enciende".', { requestId: r1 }, false, 0.15);
    notif('martina', 'job.status', 'El técnico está en camino', 'Lucas Pereyra salió hacia tu domicilio.', { jobId: j5 }, false, 0.04);
    notif('martina', 'review.new', 'Recibiste una reseña', 'Diego Fernández te dejó 5 estrellas.', { jobId: j1 }, true, 12);
    notif('diego', 'request.new', 'Nueva necesidad cerca tuyo', 'Mi notebook no enciende · a 4.2 km', { requestId: r1 }, false, 0.2);
    notif('diego', 'review.new', 'Recibiste una reseña', 'Martina Gómez te dejó 5 estrellas.', { jobId: j1 }, true, 12);
    notif('diego', 'payment.approved', 'Nuevo trabajo pago', '"Formateo + instalación de Windows y programas" ya está pago. Tu parte: $30.400.', { jobId: j1 }, true, 12);
    notif('admin', 'job.disputed', 'Nueva disputa', 'Trabajo "Instalación de cocina a gas con prueba de hermeticidad" en disputa.', { jobId: j9 }, false, 2);
    notif('hernan', 'payment.approved', 'Nuevo trabajo pago', '"Limpieza y mantenimiento de split" ya está pago. Tu parte: $39.900.', { jobId: j4 }, true, 0.15);
    notif('mariano', 'job.status', 'Trabajo terminado', 'Esperando que el cliente confirme para liberar tu pago.', { jobId: j8 }, true, 0.3);
    notif('seba', 'job.status', 'Trabajo terminado', 'El técnico marcó el trabajo como terminado. Confirmalo para liberar el pago.', { jobId: j8 }, false, 0.28);
  });
}
