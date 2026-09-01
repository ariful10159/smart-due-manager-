// A tiny phone-frame mockup so admins can see roughly how a blocking screen
// (maintenance / force-update) will look on the actual app before publishing.
export default function PhonePreview({ children }) {
  return (
    <div className="mx-auto w-full max-w-[210px] select-none">
      <div className="rounded-[26px] border-[3px] border-ink-700 bg-ink-950 p-2.5 shadow-lg">
        <div className="mx-auto mb-2 h-1.5 w-10 rounded-full bg-ink-700" />
        <div className="flex min-h-[260px] flex-col items-center justify-center gap-2 rounded-[18px] bg-ink-900 p-4 text-center">
          {children}
        </div>
      </div>
    </div>
  )
}
