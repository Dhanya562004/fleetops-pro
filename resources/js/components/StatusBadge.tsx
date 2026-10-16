const styles: Record<string, string> = {
  ready: 'bg-emerald-100 text-emerald-800',
  inspection_pending: 'bg-amber-100 text-amber-800',
  inspection: 'bg-amber-100 text-amber-800',
  repair: 'bg-orange-100 text-orange-800',
  in_repair: 'bg-orange-100 text-orange-800',
  awaiting_parts: 'bg-rose-100 text-rose-800',
  quality_check: 'bg-sky-100 text-sky-800',
  in_transit: 'bg-blue-100 text-blue-800',
  out_of_service: 'bg-stone-200 text-stone-700',
  cancelled: 'bg-stone-100 text-stone-600',
}

export function StatusBadge({ status }: { status: string }) {
  return <span className={`inline-flex whitespace-nowrap px-2 py-1 text-[10px] font-bold uppercase tracking-[.06em] ${styles[status] || 'bg-stone-100 text-stone-700'}`}>{status.replaceAll('_', ' ')}</span>
}