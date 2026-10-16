import type { ReactNode } from 'react'
import { Link, router, usePage } from '@inertiajs/react'
import { Activity, Boxes, Building2, CarFront, ChartNoAxesCombined, ClipboardList, LogOut, Wrench } from 'lucide-react'
import type { SharedProps } from '../types'
export { StatusBadge } from './StatusBadge'

const navigation = [
  { label: 'Overview', href: '/', icon: Activity },
  { label: 'Vehicles', href: '/vehicles', icon: CarFront },
  { label: 'Lot capacity', href: '/lots', icon: Building2 },
  { label: 'Repair tickets', href: '/maintenance_tickets', icon: ClipboardList },
  { label: 'Parts shortages', href: '/parts/shortages', icon: Boxes },
  { label: 'Technicians', href: '/technicians', icon: Wrench },
  { label: 'Fleet reports', href: '/analytics', icon: ChartNoAxesCombined },
]

export function AppShell({ children }: { children: ReactNode }) {
  const { url, props } = usePage<SharedProps>()
  const { currentUser, flash } = props
  return <div className="min-h-screen lg:grid lg:grid-cols-[228px_1fr]">
    <aside className="flex flex-col bg-[#14211b] text-white lg:min-h-screen">
      <div className="flex items-center gap-3 border-b border-white/10 px-5 py-5"><div className="grid h-9 w-9 place-items-center bg-lime-300 text-[#14211b]"><CarFront size={21} /></div><div><p className="font-display text-xl font-bold leading-none">FLEETOPS</p><p className="mt-1 text-[10px] font-semibold tracking-[.16em] text-lime-200">OPERATIONS / IN</p></div></div>
      <nav className="flex gap-1 overflow-x-auto px-3 py-4 lg:flex-1 lg:flex-col" aria-label="Main navigation">{navigation.map(({ label, href, icon: Icon }) => { const active = href === '/' ? url === '/' : url.startsWith(href); return <Link key={href} href={href} className={`flex shrink-0 items-center gap-3 rounded-sm px-3 py-2.5 text-sm transition-colors ${active ? 'bg-lime-300 font-semibold text-[#14211b]' : 'text-slate-300 hover:bg-white/10 hover:text-white'}`}><Icon size={17} strokeWidth={1.8} /><span>{label}</span></Link> })}</nav>
      <div className="hidden border-t border-white/10 px-4 py-4 lg:block"><p className="truncate text-sm font-semibold">{currentUser?.name}</p><p className="mt-0.5 text-xs capitalize text-slate-400">{currentUser?.role?.replace('_', ' ')}</p><button onClick={() => router.delete('/session')} className="mt-4 flex items-center gap-2 text-xs text-slate-300 hover:text-white"><LogOut size={14} />Sign out</button></div>
    </aside>
    <div className="min-w-0"><header className="flex h-14 items-center justify-between border-b border-stone-200 bg-white px-4 sm:px-7"><p className="text-xs font-semibold uppercase tracking-[.14em] text-stone-500">Fleet operations / India</p><div className="flex items-center gap-3"><span className="h-2 w-2 rounded-full bg-emerald-500" /><span className="text-xs text-stone-600">Systems operational</span><span className="ml-1 grid h-8 w-8 place-items-center rounded-full bg-stone-100 text-xs font-bold text-stone-700">{currentUser?.name?.split(' ').map((part) => part[0]).join('').slice(0, 2)}</span></div></header>
      {Object.entries(flash || {}).map(([kind, message]) => message && <div key={kind} role="status" className="border-b border-emerald-200 bg-emerald-50 px-5 py-2 text-sm text-emerald-900">{message}</div>)}<main className="ops-grid min-h-[calc(100vh-56px)] px-4 py-6 sm:px-7 sm:py-8"><div className="page-enter mx-auto max-w-[1450px]">{children}</div></main>
    </div>
  </div>
}

export function PageHeading({ eyebrow, title, description, action }: { eyebrow: string; title: string; description?: string; action?: ReactNode }) {
  return <div className="mb-6 flex flex-col gap-4 border-b border-stone-300 pb-5 sm:flex-row sm:items-end sm:justify-between"><div><p className="text-[11px] font-bold uppercase tracking-[.17em] text-fleet-700">{eyebrow}</p><h1 className="mt-1 font-display text-4xl font-semibold leading-none text-[#17221c]">{title}</h1>{description && <p className="mt-2 max-w-2xl text-sm text-stone-600">{description}</p>}</div>{action}</div>
}

export function Panel({ title, action, children, className = '' }: { title: string; action?: ReactNode; children: ReactNode; className?: string }) {
  return <section className={`border border-stone-200 bg-white ${className}`}><div className="flex items-center justify-between border-b border-stone-200 px-4 py-3"><h2 className="text-sm font-bold text-slate-800">{title}</h2>{action}</div>{children}</section>
}

export function EmptyState({ title, detail }: { title: string; detail: string }) {
  return <div className="px-5 py-12 text-center"><p className="text-sm font-semibold text-slate-700">{title}</p><p className="mt-1 text-sm text-stone-500">{detail}</p></div>
}
