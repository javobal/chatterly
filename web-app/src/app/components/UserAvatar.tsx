import { auth } from "../auth"
 
export default async function UserAvatar() {
  const session = await auth()

  if (!session?.user) return null
 
  return (
    <div>
      <h1>{session.user.name}</h1>
      <h1>{session.user.email}</h1>
      <h1>{session.user.id}</h1>
    </div>
  )
}