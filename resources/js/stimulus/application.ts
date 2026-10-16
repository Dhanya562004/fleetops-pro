import { Application } from '@hotwired/stimulus'
import '@hotwired/turbo'
import ActivityController from './controllers/activity_controller'

export function startStimulus() {
  const application = Application.start()
  application.register('activity', ActivityController)
  return application
}
