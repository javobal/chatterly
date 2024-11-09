
import { signIn } from "../auth"
 
export default function SignIn() {
  return (
    <form
      action={async () => {
        "use server"
        await signIn("cognito")
      }}
    >
      <button type="submit">Signin Cognito</button>
    </form>
  )
} 