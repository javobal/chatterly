import express from 'express'
import cors from 'cors'

const app = express()

app.use(express.json())
//app.use(morgan('tiny'))
app.use(express.static('public'))
app.use(cors())

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.listen(process.env.PORT, () => {
    console.log(`app listening at http://localhost:${process.env.PORT}`)
})