const runtimeEnv =
  typeof window !== 'undefined'
    ? ((window as Window & { __ENV__?: Record<string, string> }).__ENV__ ?? {})
    : {}

const config = {
  API_BASE_URL: import.meta.env.VITE_API_URL ?? runtimeEnv.API_URL ?? '/api',
} as const

export type Config = typeof config

export default config
