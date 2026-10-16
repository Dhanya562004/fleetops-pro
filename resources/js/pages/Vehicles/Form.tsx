import { Head, Link, useForm } from '@inertiajs/react'
import { ArrowLeft, Save } from 'lucide-react'
import { AppShell, PageHeading, Panel } from '../../components/AppShell'
import type { Lot, Vehicle } from '../../types'

type Props = { vehicle: Partial<Vehicle>; lots: Lot[] }
const statuses = ['inspection_pending', 'in_repair', 'awaiting_parts', 'quality_check', 'ready', 'out_of_service', 'in_transit']

export default function VehicleForm({ vehicle, lots, form_error }: Props & { form_error?: string }) {
  const editing = Boolean(vehicle.id)
  const form = useForm({ vin: vehicle.vin || '', make: vehicle.make || '', model: vehicle.model || '', year: vehicle.year || new Date().getFullYear(), mileage: vehicle.mileage || 0, status: vehicle.status || 'inspection_pending', lot_id: vehicle.lot_id?.toString() || '' })
  const submit = (event: React.FormEvent) => { event.preventDefault(); editing ? form.patch(`/vehicles/${vehicle.id}`) : form.post('/vehicles') }
  return <AppShell><Head title={`${editing ? 'Edit' : 'Add'} vehicle | FleetOps Pro`} /><PageHeading eyebrow="Fleet register" title={editing ? 'Edit vehicle' : 'Add vehicle'} action={<Link href="/vehicles" className="inline-flex h-10 items-center gap-2 border border-stone-300 bg-white px-3 text-sm font-semibold"><ArrowLeft size={15} />Back to fleet</Link>} />
    <Panel title="Vehicle record"><form onSubmit={submit} className="grid gap-5 p-5 sm:grid-cols-2">
      {([['vin', 'VIN'], ['make', 'Make'], ['model', 'Model'], ['year', 'Model year'], ['mileage', 'Odometer (km)']] as const).map(([key, label]) => <label key={key} className="text-sm font-semibold">{label}<input value={form.data[key]} onChange={(event) => form.setData(key, key === 'year' || key === 'mileage' ? Number(event.target.value) : event.target.value)} className="mt-2 h-10 w-full border border-stone-300 px-3 outline-none focus:border-fleet-600" required /></label>)}
      <label className="text-sm font-semibold">Status<select value={form.data.status} onChange={(event) => form.setData('status', event.target.value)} className="mt-2 h-10 w-full border border-stone-300 bg-white px-3">{statuses.map((status) => <option key={status} value={status}>{status.replaceAll('_', ' ')}</option>)}</select></label>
      <label className="text-sm font-semibold">Current lot<select value={form.data.lot_id} onChange={(event) => form.setData('lot_id', event.target.value)} className="mt-2 h-10 w-full border border-stone-300 bg-white px-3"><option value="">Unassigned</option>{lots.map((lot) => <option key={lot.id} value={lot.id}>{lot.name} / {lot.city}</option>)}</select></label>
      {(form_error || Object.values(form.errors).length > 0) && <p role="alert" className="text-sm text-rose-700 sm:col-span-2">{form_error || Object.values(form.errors).join('. ')}</p>}
      <div className="flex justify-end border-t border-stone-200 pt-4 sm:col-span-2"><button disabled={form.processing} className="inline-flex h-10 items-center gap-2 bg-[#173b2a] px-4 text-sm font-semibold text-white disabled:opacity-50"><Save size={15} />{form.processing ? 'Saving...' : 'Save vehicle'}</button></div>
    </form></Panel></AppShell>
}
