import { expect, afterEach, vi } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

// Mock Element.scrollIntoView for Radix UI components
Element.prototype.scrollIntoView = vi.fn()

// Mock PointerEvent for Radix UI components
if (typeof global.PointerEvent === 'undefined') {
  global.PointerEvent = MouseEvent as any
}

// Mock Element.prototype.hasPointerCapture
Object.defineProperty(Element.prototype, 'hasPointerCapture', {
  value: vi.fn(() => false),
  writable: true,
})

// Mock Element.prototype.setPointerCapture
Object.defineProperty(Element.prototype, 'setPointerCapture', {
  value: vi.fn(() => true),
  writable: true,
})

// Mock Element.prototype.releasePointerCapture
Object.defineProperty(Element.prototype, 'releasePointerCapture', {
  value: vi.fn(() => true),
  writable: true,
})

afterEach(() => {
  cleanup()
})
