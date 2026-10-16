import { Head } from '@inertiajs/react'
import { AppShell, PageHeading, Panel, StatusBadge } from '../../components/AppShell'

type Metrics = { average_repair_hours: string | number; average_downtime_hours: string | number; availability_percent: string | number; parts_shortage_waiting_hours: string | number; tickets_by_status: Record<string, number> }
export default function AnalyticsShow({ metrics, generated_at }: { metrics: Metrics; generated_at: string }) {
  const tickets = Object.entries(metrics.tickets_by_status).sort((a, b) => Number(b[1]) - Number(a[1]))
  const max = Math.max(1, ...tickets.map(([, count]) => Number(count)))
  return <AppShell><Head title="Fleet reports | FleetOps Pro" /><PageHeading eyebrow="Fleet performance" title="Analytics & reports" description={`Operational aggregates generated ${new Date(generated_at).toLocaleString()}. SQL-backed summary, cached for 15 minutes.`} />
    <div className="grid gap-px border border-stone-200 bg-stone-200 sm:grid-cols-2 xl:grid-cols-4">{[['Fleet availability', `${Number(metrics.availability_percent).toFixed(1)}%`], ['Average repair time', `${Number(metrics.average_repair_hours).toFixed(1)} hrs`], ['Vehicle downtime', `${Number(metrics.average_downtime_hours).toFixed(1)} hrs`], ['Parts delay impact', `${Number(metrics.parts_shortage_waiting_hours).toFixed(0)} hrs`]].map(([label, value]) => <div key={label} className="bg-white p-5"><p className="text-xs font-semibold text-stone-500">{label}</p><p className="mt-3 font-display text-4xl font-semibold">{value}</p></div>)}</div>
    <Panel title="Tickets by status" className="mt-6"><div className="space-y-4 p-5">{tickets.length ? tickets.map(([status, count]) => <div key={status} className="grid grid-cols-[150px_1fr_50px] items-center gap-3"><StatusBadge status={status} /><div className="h-3 bg-stone-100"><div className="h-full bg-fleet-600" style={{ width: `${(Number(count) / max) * 100}%` }} /></div><span className="text-right text-sm font-semibold tabular-nums">{count}</span></div>) : <p className="text-sm text-stone-500">Ticket data will appear when the first work item is recorded.</p>}</div></Panel>
    <p className="mt-4 text-xs leading-5 text-stone-500">Availability is the share of fleet vehicles currently marked ready. Repair duration uses completed ticket start-to-ready timestamps. Waiting impact sums elapsed time for tickets currently awaiting parts.</p>
  </AppShell>
}
