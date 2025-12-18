const getRuntimeEnv = () =>
  typeof window !== 'undefined'
    ? ((window as Window & { __ENV__?: Record<string, string> }).__ENV__ ?? {})
    : {}

// Use getter to defer evaluation to runtime
const config = {
  get API_BASE_URL() {
    if (import.meta.env.DEV) {
      return import.meta.env.VITE_API_URL ?? getRuntimeEnv().API_URL ?? '/api'
    }
    return getRuntimeEnv().API_URL ?? '/api'
  },
}

export type Config = typeof config

export default config
