import { Head, Link } from '@inertiajs/react'
import { ArrowLeft, Pencil } from 'lucide-react'
import { AppShell, PageHeading, Panel, StatusBadge } from '../../components/AppShell'
import type { Ticket, Vehicle } from '../../types'

export default function VehicleShow({ vehicle, tickets }: { vehicle: Vehicle; tickets: Ticket[] }) {
  return <AppShell><Head title={`${vehicle.vin} | FleetOps Pro`} /><PageHeading eyebrow="Vehicle record" title={`${vehicle.year} ${vehicle.make} ${vehicle.model}`} description={`VIN ${vehicle.vin}`} action={<div className="flex gap-2"><Link href="/vehicles" className="inline-flex h-10 items-center gap-2 border border-stone-300 bg-white px-3 text-sm font-semibold"><ArrowLeft size={15} />Fleet</Link><Link href={`/vehicles/${vehicle.id}/edit`} className="inline-flex h-10 items-center gap-2 bg-[#173b2a] px-3 text-sm font-semibold text-white"><Pencil size={15} />Edit</Link></div>} />
    <div className="grid gap-6 lg:grid-cols-[330px_1fr]"><Panel title="Vehicle status"><div className="space-y-4 p-4"><div><p className="text-xs text-stone-500">Availability</p><div className="mt-2"><StatusBadge status={vehicle.status} /></div></div><div><p className="text-xs text-stone-500">Current lot</p><p className="mt-1 text-sm font-semibold">{vehicle.lot?.name || 'Unassigned'}</p></div><div><p className="text-xs text-stone-500">Odometer</p><p className="mt-1 text-sm font-semibold">{vehicle.mileage.toLocaleString()} km</p></div></div></Panel>
      <Panel title="Maintenance history"><div className="divide-y divide-stone-100">{tickets.length ? tickets.map((ticket) => <Link key={ticket.id} href={`/maintenance_tickets/${ticket.id}`} className="flex flex-wrap items-center justify-between gap-3 px-4 py-4 hover:bg-stone-50"><div><p className="text-sm font-semibold">{ticket.title}</p><p className="mt-1 text-xs text-stone-500">{ticket.category} / {ticket.technician?.name || 'Unassigned'}</p></div><StatusBadge status={ticket.status} /></Link>) : <p className="p-5 text-sm text-stone-500">No maintenance tickets recorded.</p>}</div></Panel>
    </div>
  </AppShell>
}
