import { render, screen } from '@testing-library/react'
import { StatusBadge } from '../../resources/js/components/StatusBadge'

describe('StatusBadge', () => {
  it('renders a human-readable operational status', () => {
    render(<StatusBadge status="awaiting_parts" />)
    expect(screen.getByText('awaiting parts')).toBeInTheDocument()
  })
})